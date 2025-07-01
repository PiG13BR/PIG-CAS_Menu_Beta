/*
    File: fn_planeAttackSead.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 25/05/2025
    Update Date: 01/07/2025

    Description
        Creates a move waypoint for the aircraft and monitor its sensors to find radar targets.
        If the aircraft find those targets, it will fire automatic at them until run out of munition
     
    Parameter(s):
        _plane - [OBJECT, defaults to Objnull]
        _movePos - [POSITION, defaults to [0,0,0]]
        _magazineAndWeapon - [ARRAY, defaults to []]
    
    Returns:
        Bool - true if succeeded
*/
params[
    ["_plane", objNull, [objNull]], 
    ["_movePos", [0,0,0], [[]], [2,3]], 
    ["_magazineAndWeapon", []]
];


if (isNull _plane) exitWith {};
if (_movePos isEqualTo [0,0,0]) exitWith {_plane setVariable ["PIG_CAS_isAttacking", false]; _plane setVariable ["PIG_CAS_isBusy", false];};
if (_magazineAndWeapon isEqualTo []) exitWith {_plane setVariable ["PIG_CAS_isAttacking", false]; _plane setVariable ["PIG_CAS_isBusy", false];};

_plane setVariable ["PIG_CAS_radarTargets", []];
_plane setVariable ["PIG_CAS_targetingRadars", []];
_plane setVariable ["PIG_CAS_seadProjectiles", []];

private _magazine = _magazineAndWeapon # 0;
private _weapon = _magazineAndWeapon # 1;

private _ammo = getText(configFile >> "CfgMagazines" >> _magazine >> "ammo");

private _ammoConfigs = [configFile >> "CfgAmmo" >> _ammo >> "Components" >> "SensorsManagerComponent" >> "Components"] call BIS_fnc_returnChildren;
if (_ammoConfigs isEqualTo []) exitWith {["[CAS MENU] No ammo config children components found for %1", _ammo] call BIS_fnc_error; _plane setVariable ["PIG_CAS_isAttacking", false]; _plane setVariable ["PIG_CAS_isBusy", false];};
private _ammoPassiveRadarConfig = _ammoConfigs select {
    if (getText(_x >> "componentType") isEqualTo "PassiveRadarSensorComponent") exitWith {_x};
    false
};

if (_ammoPassiveRadarConfig isEqualTo []) exitWith {["[CAS MENU] 'PassiveRadarSensorComponent' not found in config components for %1", _ammo] call BIS_fnc_error; _plane setVariable ["PIG_CAS_isAttacking", false];  _plane setVariable ["PIG_CAS_isBusy", false];};
private _maxRangeMissile = getNumber(_ammoPassiveRadarConfig >> "GroundTarget" >> "maxRange");
//private _getSensorAngle = getNumber(_ammoPassiveRadarConfig >> "GroundTarget" >> "maxRange");
private _getSensorAngle = 30;

// Check if the aircraft already has radar targets on its sensors
/*
private _sensorsTargets = (getSensorTargets _plane) select {
    _x params ["_target", "_type", "_relationship", "_sensor"];
    if (("passiveradar" in _sensor) || ("activeradar" in _sensor) && {_relationship != "destroyed"}) then {true} else {false};
};
private _radarTargets = _sensorsTargets apply {_x # 0};
if (_radarTargets isEqualTo []) then {
    // Notification
    ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
    [(driver _plane), "Roger. Looking for radar targets."] remoteExec ["sideChat", PIG_CAS_callers];
};
*/

private _group = (group(driver _plane));
{deleteWaypoint _x} forEachReversed (wayPoints _group);
private _wp1 = _group addWaypoint [_movePos, 100];
_plane setVariable ["PIG_CAS_WAYPOINT_1_INDEX", (_wp1 # 1)];
_wayPointEH = _group addEventHandler ["WaypointComplete", {
    params ["_group", "_waypointIndex"];
    private _driver = (units _group) select {(assignedVehicleRole _x) isEqualTo ["driver"]};
	private _plane = assignedVehicle (_driver # 0);
	private _planeDriver = (driver _plane);

    if (_waypointIndex isEqualTo (_plane getVariable ["PIG_CAS_WAYPOINT_1_INDEX", 0])) then {
        _plane setVariable ["PIG_CAS_isAttacking", false];
        _plane setVariable ["PIG_CAS_isBusy", false];
        _group removeEventHandler [_thisEvent, _thisEventHandler];
    };
}];
_plane flyInHeightASL [1000, 1000, 1000];

// Fired Event Handler
private _firedEH = _plane addEventHandler ["Fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    //if !(_unit getVariable ["PIG_CAS_isAttacking", false]) exitWith {_unit removeEventHandler [_thisEvent, _thisEventHandler]};
    if ((_weapon call BIS_fnc_itemType) # 1 == "CounterMeasuresLauncher") exitWith {};
    private _magazineAndWeapon = _unit getVariable ["PIG_CAS_magazineWeaponSelected", ""];
    if !((toLowerANSI _magazine) isEqualTo (_magazineAndWeapon # 0)) exitWith {};

    if ((_unit getVariable ["PIG_CAS_attackSupportType", "SEAD"]) isEqualTo "SEAD") then {
        localNamespace setVariable ["PIG_CAS_projectileOwner", _unit];
        (_unit getVariable ["PIG_CAS_seadProjectiles", []]) pushBack _projectile;
        // hitPart or hitExplosion cannot detect if target is dead in scheduler
        /*_projectile addEventHandler ["HitExplosion", {
            params ["_projectile", "_hitEntity", "_projectileOwner", "_hitSelections", "_instigator"];
            if (isNull _hitEntity) exitWith {};
            // Spawn code to check if the unit is alive. _hitEntity will always return true in scheduled. 
            [_hitEntity, _projectileOwner] spawn {
                params ["_hitEntity", "_projectileOwner"];
                sleep 1;
                if !(alive _projectileOwner) exitWith {}; // Fail-safe
                if (!alive _hitEntity) then {
                    ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
                    [(driver _projectileOwner), "Radar target destroyed."] remoteExec ["sideChat", PIG_CAS_callers];
                }
            }
        }];*/
        // Deleted EH can detect if target is dead
        _projectile addEventHandler ["Deleted", {
            params ["_projectile"];

            private _plane = localNamespace getVariable ["PIG_CAS_projectileOwner", objNull];
            private _target = (missileTarget _projectile);

            // Delete projectile from the array
            (_plane getVariable ["PIG_CAS_seadProjectiles", []]) deleteAt ((_plane getVariable ["PIG_CAS_seadProjectiles", []]) find _projectile);
            // Only finish attack if all missiles gets deleted
            if (count (_plane getVariable ["PIG_CAS_seadProjectiles", []]) < 1) then {_plane setVariable ["PIG_CAS_isBusy", false]; _plane setVariable ["PIG_CAS_isAttacking", false]; _plane setVariable ["PIG_CAS_radarTargets", nil]; _plane setVariable ["PIG_CAS_targetingRadars", nil]; [_plane] call PIG_fnc_updateCasMenu};
            
            // Access if radar target is destroyed
            if ((!isNull _target) && (!alive _target) && (!isNull _plane)) then {
                ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
                [(driver _plane), "Radar target destroyed"] remoteExec ["sideChat", PIG_CAS_callers];

                // Delete radar targets from the array
                (_plane getVariable ["PIG_CAS_targetingRadars", []]) deleteAt ((_plane getVariable ["PIG_CAS_targetingRadars", []]) find _target);
                (_plane getVariable ["PIG_CAS_radarTargets", []]) deleteAt ((_plane getVariable ["PIG_CAS_radarTargets", []]) find _target);
            };
        }];
    };
}];

private _totalFiredTargets = [];
private _endLoop = false;
while {(alive _plane) && !_endLoop} do {
    sleep 2;

    // Check sensors for radar targets
    private _sensorsTargets = (getSensorTargets _plane) select {
        _x params ["_target", "_type", "_relationship", "_sensor"];
        if (
            (("passiveradar" in _sensor) || ("activeradar" in _sensor)) 
            && {_type == "ground"} 
            && {_relationship != "destroyed"}
            && {isVehicleRadarOn _target}
            && {((getNumber(configFile >> "cfgVehicles" >> typeOf _target >> "radarType")) == 2)}
        ) then {
                private _config = [configFile >> "CfgVehicles" >> typeOf _target >> "Components" >> "SensorsManagerComponent" >> "Components"] call BIS_fnc_returnChildren;
                if (_config isNotEqualTo []) then {
                    private _found = false;
                    {   
                        private _value = getText(_config # _forEachIndex >> "componentType");
                        if (_value isEqualTo "ActiveRadarSensorComponent") exitWith {_found = true};
                    }forEach _config;
                    if (_found) then {true} else {false};
                } else {false}; 
             } else {false};
    };
    private _radarTargets = _sensorsTargets apply {_x # 0};
    
    /*
        if (!("passiveradar" in _sensor) || {(_type != "ground")} || {(_relationship == "destroyed") || {_relationship != "enemy"}}) exitWith {};
        if (!(isVehicleRadarOn _target) || {((getNumber(configFile >> "cfgVehicles" >> typeOf _target >> "airLock")) != 4)}) exitWith {};
        private _config = [configFile >> "CfgVehicles" >> typeOf _target >> "Components" >> "SensorsManagerComponent" >> "Components"] call BIS_fnc_returnChildren;
        if (_config isEqualTo []) exitWith {};
        private _value = getText(_config # _forEachIndex >> "componentType");
        if (_value isEqualTo "ActiveRadarSensorComponent") then {_x} else {};
    */
    if (_radarTargets isNotEqualTo []) then {
    _plane setVariable ["PIG_CAS_radarTargets", _radarTargets];
    _plane selectWeapon _weapon;
    private _ammoCount = (weaponState [_plane, (_plane unitTurret (driver _plane)), (currentWeapon _plane)]) # 4; // Count ammunition in aircraft's selected weapon
    if (_ammoCount == 0 || !(_plane getVariable ["PIG_CAS_isAttacking", false])) exitWith {
        _endLoop = true;//_plane setVariable ["PIG_CAS_isAttacking", false]
    }; // Exit loop if no ammo left

        // Attack sead targets
        {  
            if (!alive _plane) exitWith {}; // Exit loop if aircraft is dead
            if (_x in _totalFiredTargets) then {continue}; // Skip fired targets
            //_plane selectWeapon _weapon;
            private _ammoCount = (weaponState [_plane, (_plane unitTurret (driver _plane)), (currentWeapon _plane)]) # 4; // Count ammunition in aircraft's selected weapon
            if (_ammoCount == 0) exitWith {}; // Exit loop if no ammo left
            (_plane getVariable ["PIG_CAS_targetingRadars", []]) pushBack _x;
            _plane move (getPos _x);
            waitUntil { sleep 2; (!alive _plane) || {(_plane distance _x <= _maxRangeMissile) && {[getPosWorld _plane, getDir _plane, _getSensorAngle, getPosWorld _x] call BIS_fnc_inAngleSector}}};
            _plane fireAtTarget [_x, _weapon]; // "weapon_harmlauncher"
            _totalFiredTargets pushBackUnique _x;
        }forEach _radarTargets;   
    };
};

if (!alive _plane) exitWith {};

_plane setVariable ["PIG_CAS_isBusy", false]; 
_plane setVariable ["PIG_CAS_isAttacking", false];
[_plane] call PIG_fnc_updateCasMenu;

[_plane, _plane getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]], _plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius]] call PIG_fnc_createLoiterWaypoint;

if (count _totalFiredTargets > 0) then {
    ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
    [(driver _plane), format ["Attack completed, fired at %1 target(s).", count _totalFiredTargets]] remoteExec ["sideChat", PIG_CAS_callers];
} else {
    ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
    [(driver _plane), "No targets found. Out."] remoteExec ["sideChat", PIG_CAS_callers];
};

_group removeEventHandler ["WaypointComplete", _wayPointEH];
_plane removeEventHandler ["Fired", _firedEH];