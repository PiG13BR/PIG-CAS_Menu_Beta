/*
    File: fn_planeAttackPlan.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 10/05/2025
    Update Date: 25/06/2025

    Description:
        Creates the path to the target for the aircraft
		Manages the final waypoints to redirect aircraft if laser from caller is detected

    Parameter(s):
       _plane - selected aircraft [OBJECT, defaults to objNull]
	   _supportType - selected support type [STRING, defaults to STRAFING RUN]
	   _magazineAndWeapon - selected magazine class and weapon class [ARRAY, defaults to []]
	   _targetPos - target position [POSITION, defaults to [0,0,0]]
	   _attackDir - target attack direction [NUMBER, defaults to 0]
	   _caller - who is calling the aircraft [OBJECT, defaults to player]
    
    Returns:
        -
*/

params [
	["_plane", objNull, [objNull]], 
	["_supportType", "STRAFING RUN", [""]], 
	["_magazineAndWeapon", [], [[]]],
	["_ammoCount", 0, [0]],
	["_targetPos", [0,0,0], [[]], [2]], 
	["_attackDir", 0, [0]], 
	["_caller", player, [objNull]]
];

if (isNull _plane) exitWith {diag_log "[CAS MENU] Plane is null"};
if (_magazineAndWeapon isEqualTo []) exitWith {};
if (_ammoCount isEqualTo 0) exitWith {};
if (_targetPos isEqualTo [0,0,0]) exitWith {diag_log "[CAS MENU] Target position is [0,0,0]"};
if (_plane getVariable ["PIG_CAS_isBusy", false]) exitWith {};

PIG_CAS_planesAttacking pushBackUnique _plane;
publicVariable "PIG_CAS_planesAttacking";

["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
[(driver _plane), "Roger. Target coordinates received."] remoteExec ["sideChat", PIG_CAS_callers];

private _planeDriver = driver _plane;
private _groupPlane = (group _planeDriver);
{deleteWaypoint _x}forEachReversed waypoints _groupPlane;

// Create logic
private _logicSide = createGroup sideLogic;
private _logic = _logicSide createUnit ["logic", _targetPos, [], 0, "NONE"]; // Placeholder. Don't move it, don't rotate it. Just for reference to get position and direction.
private _moveableLogic = _logicSide createUnit ["logic", _targetPos, [], 0, "NONE"]; // Movable placeholder. Mostly for change the jet path to the target.
_logic setDir _attackDir;
private _posATL = getPosATL _logic; // Take logic's position (target reference position). 
private _posLogic = +_posATL;
//_posLogic set [2, (_posLogic select 2) + getTerrainHeightASL _posLogic];

// approach settings
private _approachDist = 2000; // Default max distance from the target
private _approachAlt = 1500; // Attack altitude
private _approachSpeed = 400 / 3.6; // This is for vectoring aircraft. Convert to m/s
private _duration = ([0,0] distance [_approachDist, _approachAlt]) / _approachSpeed; // t = d / v

// Aircraft's variables
_plane setVariable ["PIG_CAS_isBusy", true];
_plane setVariable ["PIG_CAS_isAttacking", true];
// Get weapon type
private _weaponType = _magazineAndWeapon # 1;
_plane selectWeapon _weaponType;

// Script variables
//_plane setVariable ["PIG_CAS_vectored", false]; // The aircraft is vectored when reaches certain waypoint
_plane setVariable ["PIG_CAS_magazineWeaponSelected", _magazineAndWeapon];
_plane setVariable ["PIG_CAS_attackSupportType", _supportType];
_plane setVariable ["PIG_CAS_attackWeaponType", _weaponType];
_plane setVariable ["PIG_CAS_attackMagAmmoCount", _ammoCount];
_plane setVariable ["PIG_CAS_attackDir", _attackDir];
//_plane setVariable ["PIG_CAS_approachPos", _approachPos]; // For marker (fn_planeTracker)
_plane setVariable ["PIG_CAS_targetLogic", _logic];
_plane setVariable ["PIG_CAS_moveableLogic", _moveableLogic];
_plane setVariable ["PIG_CAS_laserTarget", objNull];
_plane setVariable ["PIG_CAS_targetOffSet", 0]; // offSet is the distance to launch the ammunition used in the setVelocityTransformation
_plane setVariable ["PIG_CAS_targets", []];
_plane setVariable ["PIG_CAS_commitAttack", false];
_plane setVariable ["PIG_CAS_attackCompleted", false];
_plane setVariable ["PIG_CAS_requireVectoring", true]; // If the aircraft needs to point to the target (to fire main gun, rockets, etc.)
_plane setVariable ["PIG_CAS_attackingEH", []];
_plane setVariable ["PIG_CAS_markedTargets", []];
_groupPlane setVariable ["PIG_CAS_waypointPathEH", []];

[_plane] call PIG_fnc_updateCasMenu;

// Create trigger to monitor attack status
private _trg = createTrigger ["EmptyDetector", [99999, 99999, 0]];
_trg setTriggerInterval 1;
_trg setVariable ["PIG_CAS_planeObject", _plane];
_trg setVariable ["PIG_CAS_callerObject", _caller];
_trg setTriggerStatements [
	toString{
		_plane = thisTrigger getVariable ["PIG_CAS_planeObject", objNull];
		_logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];

		(!(_plane getVariable ["PIG_CAS_isAttacking", false])) || {!alive _plane} || {isNull _logic}
	}, 
	toString{
		_plane = thisTrigger getVariable ["PIG_CAS_planeObject", objNull];
		_caller = thisTrigger getVariable ["PIG_CAS_callerObject", objNull];

		if ((_plane isEqualTo objNull) || {_caller isEqualTo objNull}) exitWith {deleteVehicle thisTrigger};
		_logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
		_moveableLogic = _plane getVariable ["PIG_CAS_moveableLogic", objNull];
		if !(isnull _logic) then {
			deletevehicle _logic;
			deleteVehicle _moveableLogic;
		};

		{
			_x params ["_event", "_handler"];
			_plane removeEventHandler [_event, _handler];
		}forEach (_plane getVariable ["PIG_CAS_attackingEH", []]);
		
		{(group(driver _plane)) removeEventHandler [_x # 0, _x # 1]}forEach ((group(driver _plane)) getVariable ["PIG_CAS_waypointPathEH", []]);

		_plane forceSpeed -1;
		_plane setVariable ["PIG_CAS_isBusy", false];
		[_plane] call PIG_fnc_updateCasMenu;

		if !(_plane getVariable ["PIG_CAS_isEvading", false]) then {[_plane, (_plane getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]]), (_plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius])] call PIG_fnc_createLoiterWaypoint;};

		_plane setVariable ["PIG_CAS_attackDir", nil];
		_plane setVariable ["PIG_CAS_approachPos", nil];
		_plane setVariable ["PIG_CAS_targetLogic", nil];
		_plane setVariable ["PIG_CAS_moveableLogic", nil];
		_plane setVariable ["PIG_CAS_laserTarget", nil];
		_plane setVariable ["PIG_CAS_targets", nil];
		_plane setVariable ["PIG_CAS_commitAttack", nil];
		_plane setVariable ["PIG_CAS_attackCompleted", nil];
		_plane setVariable ["PIG_CAS_requireVectoring", nil];
		_plane setVariable ["PIG_CAS_attackingEH", nil];
		_plane setVariable ["PIG_CAS_targetsMarked", nil];
		(group(driver _plane)) setVariable ["PIG_CAS_waypointPathEH", nil];

		deleteVehicle thisTrigger
	},
	toString{

	}
];

private _source = selectRandom [0,1,2];
[(driver _plane) sideRadio configName(configFile >> "CfgRadio" >> format["mp_groundsupport_50_cas_BHQ_%1", _source])] remoteExec ["sideRadio", PIG_CAS_callers];

// SEAD Attack
if (_supportType isEqualto "SEAD") exitWith {[_plane, _targetPos, _magazineAndWeapon] spawn PIG_fnc_planeAttackSead};

//private _offset = 0; // _offSet is the distance to launch the ammunition used in the setVelocityTransformation
private _distanceToFire = 1000;
private _laserCanRedirect = false;
private _approachAltitude = 1500;

switch _supportType do {
	case "STRAFING RUN" : {
		_laserCanRedirect = true;
		_distanceToFire = 700;
		//[_plane, _posLogic, _approachPos, _attackDir, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackAlt.sqf";
	};
	case "AIR-TO-GROUND" : {
		_distanceToFire = 1500;
		_attackDir = _plane getDir _targetPos;
		private _FiredEH = _plane addEventHandler ["Fired", {
			params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
			if ((_weapon call BIS_fnc_itemType) # 1 == "CounterMeasuresLauncher") exitWith {};
			_magazineAndWeapon = _unit getVariable ["PIG_CAS_magazineWeaponSelected", ""];

			if ((toLowerANSI _magazine) isEqualTo (_magazineAndWeapon # 0)) then {
				//private _targets = _plane getVariable ["PIG_CAS_targets", []];
				//private _target = _targets deleteAt (floor(random count _targets));
				_target = (_unit getVariable ["PIG_missileTarget", objNull]);
				if (isNull _target) exitWith {};
				_projectile setMissileTarget [_target, true]; // Guide the missile to the target
				//diag_log format ["[CAS MENU] AGM target system: firing at %1, with %2", str _target, str _projectile];
			};
		}];
		(_plane getVariable ["PIG_CAS_attackingEH", []]) append [["Fired", _FiredEH]];
		//[_plane, _posLogic, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackDirect.sqf";
	};
	case "GP BOMBS" : {
		_plane setVariable ["PIG_CAS_targetOffSet", 50];
		_attackDir = _plane getDir _targetPos;
		//[_plane, _posLogic, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackDirect.sqf";
	};
	case "CLUSTER" : {
		_laserCanRedirect = true;
		_plane setVariable ["PIG_CAS_targetOffSet", 100];
		private _FiredEH = _plane addEventHandler ["Fired", {
			params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

			if ((_weapon call BIS_fnc_itemType) # 1 == "CounterMeasuresLauncher") exitWith {};
			_magazineSelected = _unit getVariable ["PIG_CAS_magazineWeaponSelected", ""];

			if ((toLowerANSI _magazine) isEqualTo (_magazineSelected # 0)) then {
				["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
				[(driver _unit), "Payload delivered. Out."] remoteExec ["sideChat", PIG_CAS_callers];
				//private _target = _unit getVariable ["PIG_CAS_targetLogic", objNull];
				//if (_target isNotEqualTo objNull) then {_projectile setMissileTarget [_target, true]}; // test
				_unit removeEventHandler [_thisEvent, _thisEventHandler]
			};
		}];
		(_plane getVariable ["PIG_CAS_attackingEH", []]) append [["Fired", _FiredEH]];
		//[_plane, _posLogic, _approachPos, _attackDir, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackAlt.sqf";
		
	};
	case "LASER-GUIDED BOMBS" : {
		_plane setVariable ["PIG_CAS_requireVectoring", false];
		_distanceToFire = 1500;
		_attackDir = _plane getDir _targetPos;
		private _FiredEH = _plane addEventHandler ["Fired", {
			params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

			if ((_weapon call BIS_fnc_itemType) # 1 == "CounterMeasuresLauncher") exitWith {};
			_magazineSelected = _unit getVariable ["PIG_CAS_magazineWeaponSelected", ""];

			if ((toLowerANSI _magazine) isEqualTo (_magazineSelected # 0)) then {
				_target = (_unit getVariable ["PIG_missileTarget", objNull]);
				if (isNull _target) exitWith {};
				_projectile setMissileTarget [_target, true]; // Guide the missile to the target

			};
		}];
		private _FiredEHNotification = _plane addEventHandler ["Fired", {
			params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

			if ((_weapon call BIS_fnc_itemType) # 1 == "CounterMeasuresLauncher") exitWith {};
			_magazineSelected = _unit getVariable ["PIG_CAS_magazineWeaponSelected", ""];

			if ((toLowerANSI _magazine) isEqualTo (_magazineSelected # 0)) then {
				["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
				[(driver _unit), "Payload delivered. Out."] remoteExec ["sideChat", PIG_CAS_callers];
				_unit removeEventHandler [_thisEvent, _thisEventHandler]	
			};
		}];
		(_plane getVariable ["PIG_CAS_attackingEH", []]) append [["Fired", _FiredEH], ["Fired", _FiredEHNotification]];
		//[_plane, _posLogic, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackDirect.sqf";
	};
	case "GP ROCKETS" : {
		_plane setVariable ["PIG_CAS_targetOffSet", 20];
		_attackDir = _plane getDir _targetPos;
		//[_plane, _posLogic, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackDirect.sqf";
	};
	case "LASER-GUIDED ROCKETS" : {
		_plane setVariable ["PIG_CAS_targetOffSet", 20];
		_attackDir = _plane getDir _targetPos;
		//[_plane, _posLogic, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackDirect.sqf";
	};
	case "INFRARED AA" : {
		_plane setVariable ["PIG_CAS_requireVectoring", false];
		_distanceToFire = 900;
		_attackDir = _plane getDir _targetPos;

		private _FiredEH = _plane addEventHandler ["Fired", {
			params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
			if ((_weapon call BIS_fnc_itemType) # 1 == "CounterMeasuresLauncher") exitWith {};
			_magazineAndWeapon = _unit getVariable ["PIG_CAS_magazineWeaponSelected", ""];

			if ((toLowerANSI _magazine) isEqualTo (_magazineAndWeapon # 0)) then {
				_target = (_unit getVariable ["PIG_missileTarget", objNull]);
				if (isNull _target) exitWith {};
				_projectile setMissileTarget [_target, true]; // Guide the missile to the target
				// diag_log format ["[CAS MENU] AA IR target system: firing at %1, with %2", str _target, str _projectile];
			};
		}];
		(_plane getVariable ["PIG_CAS_attackingEH", []]) append [["Fired", _FiredEH]];
		//[_plane, _posLogic, _approachDist, _approachAlt, _distanceToFire] execVM "planeAttackDirect.sqf";
	}
};

// Approach
private _approachPos = _posLogic getPos [_approachDist, _attackDir + 180]; // Vector position relative to the target position
_approachPos set [2, ((_posLogic select 2) + getTerrainHeightASL _posLogic) + _approachAlt]; // Set altitude

_planeDriver setBehaviourStrong "CARELESS"; // The flight altitude can only be achieve 100% by putting the AI in careless mode
_plane flyInHeightASL [(_approachPos select 2), (_approachPos select 2), (_approachPos select 2)];
_plane forceSpeed 600/3.6;

private _pathPos1 = _approachPos getPos [_approachDist, (_attackDir + 180)];
_pathPos1 set [2, (_approachPos select 2)]; // Set altitude

if (_plane distance2d _targetPos <= _pathPos1 distance2d _targetPos) then {
    // Aircraft too near of the target position.
    _pathPosDistant = _pathPos1 getPos [_approachDist, (_attackDir + 180)];
    private _wp0 = (group _planeDriver) addWaypoint [_pathPosDistant, 0];
    _wp0 setWaypointSpeed "FULL";
    _plane flyInHeightASL [(_approachPos select 2), (_approachPos select 2), (_approachPos select 2)];
    _plane setVariable ["PIG_CAS_WAYPOINT_0_INDEX", (_wp0 # 1)];
};

private _wp1 = (group _planeDriver) addWaypoint [_pathPos1, 0];
_wp1 setWaypointSpeed "NORMAL";
_plane setVariable ["PIG_CAS_WAYPOINT_1_INDEX", (_wp1 # 1)];
_wp1 setWaypointCompletionRadius 500;

private _pathPos2 = (waypointPosition _wp1) getPos [_approachDist/2, _attackDir];
_pathPos2 set [2, (_approachPos select 2)]; // Set altitude
private _wp2 = (group _planeDriver) addWaypoint [_pathPos2, 0];
_plane setVariable ["PIG_CAS_WAYPOINT_2_INDEX", (_wp2 # 1)];
_wp2 setWaypointSpeed "LIMITED";
_wp2 setWaypointCompletionRadius 500;

private _wp3 = (group _planeDriver) addWaypoint [_approachPos, 0];
_plane setVariable ["PIG_CAS_WAYPOINT_3_INDEX", (_wp3 # 1)];
_wp3 setWaypointCompletionRadius 500;

private _pathPosFire = _targetPos getPos [_distanceToFire, _attackDir + 180];
_pathPosFire set [2, (_approachPos select 2)]; // Set altitude
private _wpFire = (group _planeDriver) addWaypoint [_pathPosFire, 0];
_plane setVariable ["PIG_CAS_WAYPOINT_FIRE_INDEX", (_wpFire # 1)];
_wpFire setWaypointCompletionRadius 500;

private _wp4 = (group _planeDriver) addWaypoint [_targetPos, 0];
_wp4 setWaypointCompletionRadius 500;

// Waypoint EH
_waypointEH = (group _plane) addEventHandler ["WaypointComplete", {
    params ["_group", "_waypointIndex"];
    private _driver = (units _group) select {(assignedVehicleRole _x) isEqualTo ["driver"]};
    private _plane = assignedVehicle (_driver # 0);
    private _planeDriver = (driver _plane);
    private _supportType = _plane getVariable ["PIG_CAS_attackSupportType", "STRAFING RUN"];

    switch _waypointIndex do {
        case (_plane getVariable ["PIG_CAS_WAYPOINT_1_INDEX", 1]) : {
            //private _attackDir = _plane getVariable ["PIG_CAS_attackDir", 0];
			["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
			[_planeDriver, "Reaching at target coordinates."] remoteExec ["sideChat", PIG_CAS_callers];
			if (_supportType == "INFRARED AA") then {
                _plane flyInHeightASL [400, 400, 400]; // approach in lower altitude
            };
            /*
			[_plane, _attackDir, _group] spawn {
                params["_plane", "_attackDir", "_group"];
                // Force vectoring/snap aircraft to attack path
                
                for "_dir" from (getDir _plane) to (_attackDir) do {
                    sleep 0.01;
                    systemChat format ["Plane dir: %1, Attack Dir: %2", _dir, _attackDir];
                    _plane setVectorDirAndUp [[sin _dir, cos _dir, 0], [0,0,1]]; 
                    private _vel = velocityModelSpace _plane; 
                    _plane setVelocityModelSpace _vel;
                };
            };
			*/
        };
        case (_plane getVariable ["PIG_CAS_WAYPOINT_2_INDEX", 1]) : {
            if (_supportType == "LASER-GUIDED BOMBS") then {
                _plane flyInHeightASL [700, 700, 700]; // approach in lower altitude
            };
        };
        // Waypoint to target
        case (_plane getVariable ["PIG_CAS_WAYPOINT_3_INDEX", 2]) : {
            _plane setVariable ["PIG_CAS_commitAttack", true];
        
            private _requireVectoring = _plane getVariable ["PIG_CAS_requireVectoring", false];
            if (_requireVectoring) then {
                [_plane] spawn PIG_fnc_planeVectorToTarget;
            };
        };
        // Fire waypoint
        case (_plane getVariable ["PIG_CAS_WAYPOINT_FIRE_INDEX", 3]) : {
            private _logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
            private _weaponType = _plane getVariable ["PIG_CAS_attackWeaponType", ""];
            private _laserTarget = _plane getVariable ["PIG_CAS_laserTarget", objNull];
            private _ammoCount = _plane getVariable ["PIG_CAS_attackMagAmmoCount", 0];

            switch _supportType do {
                case "AIR-TO-GROUND" : {
                    // Find IR ground targets
                    private _targets = ((getPos _logic) nearEntities ["landVehicle", PIG_CAS_AGMSearchRadius]) select {
                        ((alive _x) && {_x isKindOf "landVehicle"} && {isEngineOn _x} && {((side _planeDriver) getFriend (side _x)) < 0.6})
                    };
                    (_plane getVariable ["PIG_CAS_targets", []]) append _targets;
                };
                case "INFRARED AA" : {
                    // Find IR air targets (helicopters)
                    private _targets = ((getPos _logic) nearEntities ["Helicopter", PIG_CAS_AAIRSearchRadius]) select {
                        ((alive _x) && {_x isKindOf "Helicopter"} && {isEngineOn _x} && {((side _planeDriver) getFriend (side _x)) < 0.6})
                    };
                    (_plane getVariable ["PIG_CAS_targets", []]) append _targets;
                }
            };
                [_plane, _planeDriver, _logic, _laserTarget, _supportType, _weaponType, _ammoCount] spawn PIG_fnc_planeFire;
        }
    }
}];

((group _plane) getVariable ["PIG_CAS_waypointPathEH", []]) pushBack ["WaypointComplete", _waypointEH];
/*
// Waypoints (attack path pattern)
private _pathPos1 = _approachPos getPos [_approachDist + 1000, ((_attackDir + 180) + 45)];
_pathPos1 set [2, (_approachPos select 2)]; // Set altitude
private _wp1 = (group _planeDriver) addWaypoint [_pathPos1, 0];

private _pathPos2 = (waypointPosition _wp1) getPos [_approachDist, (_attackDir + 180) - 45];
_pathPos2 set [2, (_approachPos select 2)]; // Set altitude
private _wp2 = (group _planeDriver) addWaypoint [_pathPos2, 0];

private _pathPos3 = _approachPos getPos [_approachDist, (_attackDir + 180)];
_pathPos3 set [2, (_approachPos select 2)]; // Set altitude
private _wp3 = (group _planeDriver) addWaypoint [_pathPos3, 0];
_wp3 setWaypointSpeed "LIMITED"; // Slow the airplane down
_plane setVariable ["PIG_CAS_WAYPOINT_3_INDEX", (_wp3 # 1)];

private _pathPos4 = (waypointPosition _wp3) getPos [_approachDist/2, _attackDir];
_pathPos4 set [2, (_approachPos select 2)]; // Set altitude
private _wp4 = (group _planeDriver) addWaypoint [_pathPos4, 0];
_plane setVariable ["PIG_CAS_WAYPOINT_4_INDEX", (_wp4 # 1)];
// Final vector, the aircraft is now in the final path to attack
_wp4 setWaypointSpeed "NORMAL";

private _wp5 = (group _planeDriver) addWaypoint [_approachPos, 0];
_plane setVariable ["PIG_CAS_WAYPOINT_5_INDEX", (_wp5 # 1)];

private _pathPosFire = _posLogic getPos [_distanceToFire, _attackDir + 180];
_pathPosFire set [2, (_approachPos select 2)]; // Set altitude
private _wpFire = (group _planeDriver) addWaypoint [_pathPosFire, 0];
_plane setVariable ["PIG_CAS_WAYPOINT_FIRE_INDEX", (_wpFire # 1)];

private _wp6 = (group _planeDriver) addWaypoint [_posLogic, 0];

private _waypointEH = _groupPlane addEventHandler ["WaypointComplete", {
	params ["_group", "_waypointIndex"];
	private _driver = (units _group) select {(assignedVehicleRole _x) isEqualTo ["driver"]};
	private _plane = assignedVehicle (_driver # 0);
	private _planeDriver = (driver _plane);
	private _supportType = _plane getVariable ["PIG_CAS_attackSupportType", "STRAFING RUN"];
	
	switch _waypointIndex do {
		case (_plane getVariable ["PIG_CAS_WAYPOINT_3_INDEX", 2]) : {
			private _attackDir = _plane getVariable ["PIG_CAS_attackDir", 0];
			private _attackPos = _plane getVariable ["PIG_CAS_targetLogic", objNull];
			if (_attackPos isEqualTo objNull) exitWith {["[CAS MENU] Could not find the attack target" call bis_fnc_error]};
			_eta = (_plane distance _attackPos) / (speed _plane / 3.6);

			// Force vectoring/snap aircraft to attack path
			_plane setVectorDirAndUp [[sin _attackDir, cos _attackDir, 0], [0,0,1]]; 
			private _vel = velocityModelSpace _plane; 
			_plane setVelocityModelSpace _vel;

			private _groupID = _plane getVariable ["PIG_CAS_pilotGroupID", groupID _group];
			["PIG_CAS_ETA_Notification", [_groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
		};
		case (_plane getVariable ["PIG_CAS_WAYPOINT_4_INDEX", 3]) : {
			//_plane setVariable ["PIG_CAS_vectored", true];
			private _laserTarget = _plane getVariable ["PIG_CAS_laserTarget", objNull];
			
			if ((_supportType == "LASER-GUIDED BOMBS") || (_supportType == "CLUSTER")) then {
				private _approachPos = _plane getVariable ["PIG_CAS_approachPos", _approachPos];
				_plane flyInHeightASL [(((_approachPos select 2) - 500) max 900), (_approachPos select 2), (_approachPos select 2)]; // approach in lower altitude
				_planeDriver setBehaviourStrong "CARELESS";
			};
		};
		// Waypoint to target
		case (_plane getVariable ["PIG_CAS_WAYPOINT_5_INDEX", 4]) : {
			_plane setVariable ["PIG_CAS_commitAttack", true];

			//if (count (_plane getVariable ["PIG_CAS_targets", []]) == 0) exitWith {}; // Exit on empty array
			//_plane flyInHeightASL [(_approachPos select 2), 300, 300];
			
			["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
			[_planeDriver, "Reaching at target coordinates."] remoteExec ["sideChat", PIG_CAS_callers];
			private _requireVectoring = _plane getVariable ["PIG_CAS_requireVectoring", false];
			if (_requireVectoring) then {
				[_plane] spawn PIG_fnc_planeVectorToTarget;
			};
		};
		// Fire waypoint
		case (_plane getVariable ["PIG_CAS_WAYPOINT_FIRE_INDEX", 5]) : {
			private _logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
			private _weaponType = _plane getVariable ["PIG_CAS_attackWeaponType", ""];
			private _laserTarget = _plane getVariable ["PIG_CAS_laserTarget", objNull];
			private _ammoCount = _plane getVariable ["PIG_CAS_attackMagAmmoCount", 0];

			switch _supportType do {
				case "AIR-TO-GROUND" : {
					// Find IR ground targets
					private _targets = ((getPos _logic) nearEntities ["landVehicle", PIG_CAS_AGMSearchRadius]) select {
						((alive _x) && {_x isKindOf "landVehicle"} && {isEngineOn _x} && {((side _planeDriver) getFriend (side _x)) < 0.6})
					};
					(_plane getVariable ["PIG_CAS_targets", []]) append _targets;
				};
				case "AA" : {
					// Find IR air targets (helicopters)
					private _targets = ((getPos _logic) nearEntities ["Helicopter", PIG_CAS_AAIRSearchRadius]) select {
						((alive _x) && {_x isKindOf "Helicopter"} && {isEngineOn _x} && {((side _planeDriver) getFriend (side _x)) < 0.6})
					};
					(_plane getVariable ["PIG_CAS_targets", []]) append _targets;
				}
			};
			[_plane, _planeDriver, _logic, _laserTarget, _supportType, _weaponType, _ammoCount] spawn PIG_fnc_planeFire;
		};
	}
}];
*/
// Cancel CAS support if airplane is attacked
private _incomingEH = _plane addEventHandler ["IncomingMissile", {
	params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];

	_target setVariable ["PIG_CAS_isAttacking", false];
	_target setVariable ["PIG_CAS_attackCompleted", true];
	_target removeEventHandler [_thisEvent, _thisEventHandler];
}];

private _hitEH = _plane addEventHandler ["Hit", {
	params ["_unit", "_source", "_damage", "_instigator"];
	if ((_damage > 0.2) && ((side _source) getFriend (side _unit) < 0.6)) then {
		_unit setVariable ["PIG_CAS_isAttacking", false];
		_unit setVariable ["PIG_CAS_attackCompleted", true];
		["PIG_CAS_Attacked_Notification", [(groupID (group (driver _unit))), (groupID (group (driver _unit)))]] remoteExec ["BIS_fnc_showNotification", 0];
		_target removeEventHandler [_thisEvent, _thisEventHandler];
	};
}];

(_plane getVariable ["PIG_CAS_attackingEH", []]) append [["IncomingMissile", _incomingEH], ["Hit", _hitEH]];

if (_supportType == "GP BOMBS") exitWith {};

private _planeSide = _plane getVariable ["PIG_CAS_pilotSide", side _planeDriver];

private _laserType = switch _planeSide do {
	case west : {"LaserTargetW"};
	case east : {"LaserTargetE"};
	case independent : {"LaserTargetI"};
	default {""};
};

[_logic, _plane, _laserType, _approachDist, _approachAlt, _attackDir, _distanceToFire, _moveableLogic, _wp1, _wp2, _wp3, _wpFire, _wp4, _posLogic, _pathPos1, _pathPos2, _approachPos, _pathPosFire] spawn {
	params['_logic', '_plane', '_laserType', '_approachDist', '_approachAlt', '_attackDir', '_distanceToFire', '_moveableLogic', '_wp1', '_wp2', '_wp3', '_wpFire', '_wp4', '_posLogic', '_pathPos1', '_pathPos2', '_approachPos', '_pathPosFire'];
	//diag_log str _this;

	while {(!isNull _logic) && (alive _plane) && (!isNull _plane) && (_plane getVariable ["PIG_CAS_isAttacking", false])} do {
		//private _fireProgress = _plane getvariable ["PIG_CAS_fireProgress", 0];

		//if (_isFiring) then { systemChat "firing"; continue }; // Skip iteration if aircraft is firing

		// Find laser object to change logic's position. This will keep updating the target position until the aircraft fires
		private _laserTarget = (((getPosATL _logic) nearEntities [_laserType, 200])) param [0, objNull];
		if (!isNull _laserTarget) then {
			_plane setVariable ["PIG_CAS_laserTarget", _laserTarget];
			// UPDATE LASER POSITION
			_moveableLogic setPosATL (getPosATL _laserTarget);
			//_moveableLogic setDir _attackDir;
			// WAYPOINTS UPDATE - This helps the AI aircraft to keep on the right path to the target, once it reaches the last waypoint, it's committed to attack, so this update is not needed anymore
			if !(_plane getVariable ["PIG_CAS_commitAttack", false]) then {
				// Private variables for this scope to not change the original values
				private _posATL = getPosATL _moveableLogic; 
				private _posLogic = +_posATL;
				//_posLogic set [2, (_posLogic select 2) + getTerrainHeightASL _posLogic];
				private  _approachPos = _posLogic getPos [_approachDist, (_attackDir + 180)]; 
				_approachPos set [2, ((_posLogic select 2) + getTerrainHeightASL _posLogic) + _approachAlt]; // Set altitude
				private _pathPos1 = _approachPos getPos [_approachDist, (_attackDir + 180)];
				_pathPos1 set [2, (_approachPos select 2)]; // Set altitude
				_wp1 setWaypointPosition [_pathPos1, 0];

				private _pathPos2 = (waypointPosition _wp1) getPos [_approachDist/2, _attackDir];
				_pathPos2 set [2, (_approachPos select 2)]; // Set altitude
				_wp2 setWaypointPosition [_pathPos2, 0];

				_wp3 setWaypointPosition [_approachPos, 0];

				private _pathPosFire = _posLogic getPos [_distanceToFire, (_attackDir + 180)];
				_pathPosFire set [2, (_approachPos select 2)]; // Set altitude
				_wpFire setWaypointPosition [_pathPosFire, 0];

				_wp4 setWaypointPosition [_posLogic, 0];
			};
		} else {
			_plane setVariable ["PIG_CAS_laserTarget", objNull];
			// RESTORE LOGIC'S ORIGINAL POSITION
			_moveableLogic setPosATL _posLogic;
			//_moveableLogic setDir _attackDir;
			// RESTORE WAYPOINTS TO ORIGINAL PATHS
			if !(_plane getVariable ["PIG_CAS_commitAttack", false]) then {
				_wp1 setWaypointPosition [_pathPos1, 0];
				_wp2 setWaypointPosition [_pathPos2, 0];
				_wp3 setWaypointPosition [_approachPos, 0];
				_wpFire setWaypointPosition [_pathPosFire, 0];
				_wp4 setWaypointPosition [_posLogic, 0];
			};
		};

		sleep 0.5;
	};
};

