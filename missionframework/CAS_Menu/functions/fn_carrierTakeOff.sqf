/*
    File: fn_carrierTakeOff.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 02/05/2025
    Update Date: 16/06/2025

    Description:
        Manages the aircraft's take off of a carrier

    Parameter(s):
       _plane - aircraft object [OBJECT, defaults to objNull]
       _carrierClass - carrier class [STRING, defaults to "Land_Carrier_01_base_F" (USS Freedom)]
    
    Returns:
       [BOOL]
*/

params[
	["_plane", objNull, [ObjNull]],
	["_carrierClass", "Land_Carrier_01_base_F", [""]] // Carrier USS Freedom as default
];

if ((isNull _plane) || {!(_plane isKindOf "Plane")}) exitWith {["[CAS MENU] No aircraft provided"] call BIS_fnc_error; false};
if !(_plane getVariable ["PIG_CAS_planeOnCarrier", false]) exitWith {false};

// Create variable to track down busy catapults
if (isNil "PIG_CAS_busyCatapults") then {
    PIG_CAS_busyCatapults = [];
    publicVariable "PIG_CAS_busyCatapults";
};

private _catapultsCfgArray = [_carrierClass] call PIG_fnc_getCarrierCatapults; // Get all catapults
if (_catapultsCfgArray isEqualTo []) exitWith {systemChat "No catapults available"; false};

// Eject any crew
if (count (crew _plane) > 0) then {
    {if (!isPlayer _x) then {_plane deleteVehicleCrew _x} else {moveOut _x}}forEach crew _plane;
};

// Create crew
[_plane] call PIG_fnc_planeCreateCrew;
//createVehicleCrew _plane;

{ detach _x } forEach attachedObjects (_plane getVariable "PIG_CAS_attachedLogic");

// Boolean variables
_plane setVariable ["PIG_CAS_isTakingOff", true, true];
_plane setVariable ["PIG_CAS_isOnBase", false, true];
_plane setVariable ["PIG_CAS_isBusy", true, true];

private _selectedCfg = selectRandom _catapultsCfgArray;

_selectedCfg params ["_cfgCatapults", "_hullClass"];

// Select random one catapult cfg (hull_07 in USS Freedom has two catapult classes)
private _catapultSelected = "";
if (_cfgCatapults isEqualType "") then {
    _catapultSelected = _cfgCatapults;
} else {
    _catapultSelected = selectRandom _cfgCatapults;
};

// Add as a busy catapult
PIG_CAS_busyCatapults pushBack (str _catapultSelected); // Pass as string
publicVariable "PIG_CAS_busyCatapults";

private _memPoint = getText(_catapultSelected >> "memoryPoint");
private _dirOffset = getNumber(_catapultSelected >> "dirOffset");
private _deflectorsArray = getArray(_catapultSelected >> "animations");
private _hullArray = nearestObjects [(getPosATL _plane), [_hullClass], 500, true]; // 2d radius search 
private _hull = (_hullArray # 0);

// Set jet position and direction (Extracted from BIS_fnc_Carrier01CatapultLockTo)
private _posStart = getPosWorld _plane;
private _height = _posStart select 2; // Get height from the jet
private _posCatapult = _hull modelToWorld (_hull selectionPosition _memPoint);
private _dirCatapult = (getDir _hull - _dirOffset - 180) % 360;
_posCatapult set [2, _height];
_plane setPosWorld _posCatapult;
_plane setDir _dirCatapult;

[_plane, false] call PIG_fnc_aircraftFoldingWings; // Unfold wings if supported
[_plane, _hull, _memPoint, _dirOffset, _deflectorsArray, (str _catapultSelected)] spawn PIG_fnc_planeLaunchSequence;
/*
[_plane, _hull, _memPoint, _dirOffset, _deflectorsArray, _catapultSelected] spawn {
    params['_plane','_hull', '_memPoint', '_dirOffset', '_deflectorsArray', '_catapultSelected'];
    //sleep 10;
    [_plane, _hull, _memPoint, _dirOffset, _deflectorsArray, _catapultSelected] spawn PIG_fnc_planeLaunchSequence;
};
*/
/*
[_plane, _hull, _memPoint, _dirOffset, _deflectorsArray, _catapultSelected] spawn {
    params["_plane", "_hull", "_memPoint", "_dirOffset", "_deflectorsArray", "_catapultSelected"];
    
    if (_memPoint isNotEqualTo "") then {
        _plane setPhysicsCollisionFlag false; // Disable collision
        // Lock to the available catapult
        [_plane, _hull, _memPoint, _dirOffset] spawn PIG_fnc_lockPlaneToCatapult;
        if (_deflectorsArray isNotEqualTo []) then {
            // With deflectors
            [_hull, _deflectorsArray, 10] spawn BIS_fnc_carrier01AnimateDeflectors; // Deflectors up

            sleep 11; // Wait deflectors animation to be completed

            _plane setVariable ["PIG_CAS_catapulted", true];
            // [_plane] call BIS_fnc_aircraftCatapultLaunch; // Use BIS function to launch airplane
            [_plane] call PIG_fnc_aircraftCatapultLaunch; // With small modifications

            //_plane doMove (_plane getPos [700, (getDir _plane)]);
            [_plane, 2500] call PIG_fnc_carrierPathTakeOff;
            //[_plane, 2500] execVM "carrierTakeOffPath.sqf";
            sleep 5;
            
            [_hull, _deflectorsArray, 0] spawn BIS_fnc_carrier01AnimateDeflectors; // Deflectors down
        } else {
            // Without deflectors
            sleep 5;
            _plane setVariable ["PIG_CAS_catapulted", true];
            [_plane] call PIG_fnc_aircraftCatapultLaunch; 
            diag_log "[CAS MENU] No deflectors animations found";
        };

        PIG_CAS_busyCatapults = PIG_CAS_busyCatapults - [_catapultSelected];
        publicVariable "PIG_CAS_busyCatapults";

        _plane setPhysicsCollisionFlag true;
        _plane setVariable ["PIG_CAS_catapulted", false];
    } else {
        ["[CAS MENU] No memory point found"] call BIS_fnc_error
    };
    
};
*/

// Add EH
[_plane] call PIG_fnc_planeAddEH;
PIG_CAS_planesInAir pushBackUnique _plane;
publicVariable "PIG_CAS_planesInAir";

//[_plane] call PIG_fnc_planeMonitorSensors;
/*
// ((thisTrigger getVariable ["PIG_CAS_trgJetObject", objNull]) distance2d thisTrigger <= (thisTrigger getVariable ["PIG_CAS_trgLoiterRadius", PIG_CAS_LoiterMinRadius]) + 500) && 
// Trigger to check distance from loiter position and make support available
_trg = createTrigger ["EmptyDetector", _loiterPos, false];
_trg setVariable ["PIG_CAS_trgLoiterRadius", _loiterRadius];
_trg setVariable ["PIG_CAS_trgJetObject", _plane];
_trg setTriggerStatements [
    toString {((getPosATL (thisTrigger getVariable ["PIG_CAS_trgJetObject", objNull])) # 2) >= (PIG_CAS_LoiterAltitude - 150)}, 
    toString {
        _plane = (thisTrigger getVariable ["PIG_CAS_trgJetObject", objNull]);

        _plane allowDamage true;
        (driver _plane) allowDamage true;
        _groupID = (group (driver _plane));

        ["PIG_CAS_Available_Notification", [_groupID, _groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
        _plane spawn {
            if (missionNamespace getVariable ["PIG_CAS_activateCasRadioMsg", true]) then {
                missionNamespace setVariable ["PIG_CAS_activateCasRadioMsg", false];
                private _source = selectRandom [0,1,2];
                [(driver _this) sideRadio configName(configFile >> "CfgRadio" >> format["mp_groundsupport_05_newpilot_BHQ_%1", _source])] remoteExec ["sideRadio", PIG_CAS_callers];
                sleep 30; 
                missionNamespace setVariable ["PIG_CAS_activateCasRadioMsg", true];
            }
        };
        [_plane] spawn PIG_fnc_monitorFuel;

        //missionNamespace setVariable ["PIG_CAS_supportAvailable", true, true];
        _plane setVariable ["PIG_CAS_isTakingOff", false, true];
        _plane setVariable ["PIG_CAS_isBusy", false, true];

        [_plane] call PIG_fnc_updateCasMenu;

        (driver _plane) disableAI "LIGHTS";
        _plane setCollisionLight false;

        deleteVehicle thisTrigger;
    }, 
    toString {}
];
_trg setTriggerInterval 2;
*/
_plane addEventHandler ["Gear", {
	params ["_plane", "_gearState"];
    if !(_gearState) then {
                _plane allowDamage true;
        (driver _plane) allowDamage true;
        _groupID = (group (driver _plane));

        ["PIG_CAS_Available_Notification", [_groupID, _groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
        _plane spawn {
            if (missionNamespace getVariable ["PIG_CAS_activateCasRadioMsg", true]) then {
                missionNamespace setVariable ["PIG_CAS_activateCasRadioMsg", false, true];
                private _source = selectRandom [0,1,2];
                [(driver _this) sideRadio configName(configFile >> "CfgRadio" >> format["mp_groundsupport_05_newpilot_BHQ_%1", _source])] remoteExec ["sideRadio", PIG_CAS_callers];
                sleep 30; 
                missionNamespace setVariable ["PIG_CAS_activateCasRadioMsg", true, true];
            }
        };
        [_plane] spawn PIG_fnc_monitorFuel;

        //missionNamespace setVariable ["PIG_CAS_supportAvailable", true, true];
        _plane setVariable ["PIG_CAS_isTakingOff", false, true];
        _plane setVariable ["PIG_CAS_isBusy", false, true];

        [_plane] call PIG_fnc_updateCasMenu;

        (driver _plane) disableAI "LIGHTS";
        _plane setCollisionLight false;
        _plane removeEventHandler [_thisEvent, _thisEventHandler]
    }
}];

true