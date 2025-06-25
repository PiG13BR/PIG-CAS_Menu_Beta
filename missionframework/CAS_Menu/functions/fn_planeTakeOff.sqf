/*
    File: fn_planeTakeOff.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 29/04/2025
    Update Date: 16/06/2025

    Description
        Manages the taking off of the selected aircraft from the menu
    
    Parameter(s):
        _plane - selected aircraft [OBJECT, defaults to objNull]
        _loiterPos - position where the aircraft will loiter [POSITION, defaults to [0,0,0]]
        _loiterRadius - loiter radius [NUMBER, defaults to minimun value from configs]
    
    Returns:
        Bool - true if succeeded
*/

params[
    ["_plane", objNull, [objNull]], 
    ["_loiterPos", [0,0,0], [[]]], 
    ["_loiterRadius", PIG_CAS_LoiterMinRadius, [0]]
];

if (isNull _plane) exitWith {false};
if (_loiterPos isEqualTo [0,0,0]) exitWith {false};

// if the aircraft can take off from a carrier, manages it with another function
if (_plane getVariable ["PIG_CAS_planeOnCarrier", false]) exitWith {_canTakeOff = [_plane] call PIG_fnc_carrierTakeOff; _canTakeOff};

// Eject any crew
if (count (crew _plane) > 0) then {
    {if (!isPlayer _x) then {_plane deleteVehicleCrew _x} else {moveOut _x}}forEach crew _plane;
};

// Create crew
[_plane] call PIG_fnc_planeCreateCrew;
/*
_pilotClass = _plane getVariable "PIG_CAS_pilotClass";
_pilotSide = _plane getVariable "PIG_CAS_pilotSide";
_pilotGroupID = _plane getVariable "PIG_CAS_pilotGroupID";
private _group = createGroup _pilotSide;
_group setGroupIdGlobal [_pilotGroupID];
_group setGroupId [_pilotGroupID];
_driver = _group createUnit [_pilotClass, getPosATL _plane, [], 10, "NONE"];
_driver moveInDriver _plane;
_driver disableAI "TARGET";
_driver disableAI "AUTOTARGET";
_driver setCombatMode "BLUE";
//_driver setBehaviourStrong "CARELESS";
_driver disableAI "RADIOPROTOCOL";
*/

{ detach _x } forEach attachedObjects (_plane getVariable "PIG_CAS_attachedLogic");

// Boolean variables
_plane setVariable ["PIG_CAS_isTakingOff", true, true];
_plane setVariable ["PIG_CAS_isOnBase", false, true];
_plane setVariable ["PIG_CAS_isBusy", true, true];

// Catapult the aircraft if is on carrier
if (_plane getVariable ["PIG_CAS_planeOnCarrier", false]) then {
    //_canTakeOff = [_plane] call PIG_fnc_carrierTakeOff;
} else {
    _plane setVelocityModelSpace [0,20,0]; // Give it a slight push
    [_plane, _loiterPos, _loiterRadius] call PIG_fnc_createLoiterWaypoint;
};
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
/*
    _plane spawn {
        // 
        waitUntil {sleep 1; ((getPosATL _this) # 2) >= PIG_CAS_LoiterAltitude}; 

        _this allowDamage true;
        (driver _this) allowDamage true;

        ["PIG_CAS_Available_Notification", [(groupID (group (driver _this))), (groupID (group (driver _this)))]] remoteExec ["BIS_fnc_showNotification", 0];
        missionNamespace setVariable ["PIG_CAS_supportAvailable", true, true];
        [] call PIG_fnc_updateCasMenu;
    };
*/

// Add EH
[_plane] call PIG_fnc_planeAddEH;
PIG_CAS_planesInAir pushBackUnique _plane;
publicVariable "PIG_CAS_planesInAir";

//[_plane] call PIG_fnc_planeMonitorSensors;

true