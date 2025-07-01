/*
    File: fn_evasiveManeuver.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 03/05/2025
    Update Date: 22/06/2025

    Description:
        Make AI jet do an evasive maneuver to escape from missiles.

    Parameter(s):
       _plane - AI aircraft (Target) [OBJECT, defaults to objNull]
	   _threat - Unit that shot the missile [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params[["_plane", objNull, [objNull]], ["_threat", objNull, [objNull]]];

if (_plane isEqualTo objNull) exitWith {["[CAS MENU] Plane target is null"] call bis_fnc_error;};
if (_threat isEqualTo objNull) exitWith {diag_log "[CAS MENU] Source is null"; [_plane, "incomingmissile"] call PIG_fnc_planeAddEH;};

if ((_plane getVariable ["PIG_CAS_isRTB", false]) && (_plane getVariable ["PIG_CAS_isOnBase", false])) exitWith {};
if (_plane getVariable ["PIG_CAS_isEvading", false]) exitWith {};
_plane setVariable ["PIG_CAS_isEvading", true];

_plane setVariable ["PIG_CAS_isBusy", true];
_plane setVariable ["PIG_CAS_isAttacking", false];
[_plane] call PIG_fnc_updateCasMenu;

{deleteWaypoint _x}forEachReversed waypoints (group (driver _plane));
(group(driver _plane)) setSpeedMode "FULL";

// Dive
//_plane flyInHeightASL [300, 300, 300];
private _evadeDest = (_plane getPos [2000, (getDir _plane)]);
_plane moveTo _evadeDest;
_plane flyInHeight [300, true];
//(group(driver _plane)) setBehaviourStrong "COMBAT"; // It will dive because of flyInHeightASL
_plane setVelocityModelSpace [0,100,0];

[_plane, _threat] spawn {
	params ["_plane", "_threat"];
    
    /*
        createMarkerLocal ["PIG_CAS_threatPos", (getPos _threat)];
        "PIG_CAS_threatPos" setMarkerTypeLocal "waypoint";
        "PIG_CAS_threatPos" setMarkerTextLocal "Threat position";
        "PIG_CAS_threatPos" setMarkerColorLocal "colorRED";
    */

    private _counterMeasuresArray = _plane getVariable ["PIG_CAS_jetCounterMeasures", []];
    private _counterMeasure = selectRandom _counterMeasuresArray;
    _counterModes = (getArray (configFile >> "CfgWeapons" >> _counterMeasure >> "modes"));

    // Fire flares while diving
    for "_i" from 0 to (10 + ceil(random 10)) do {
        sleep 0.5;
	    (driver _plane) forceWeaponFire [_counterMeasure, (selectRandom _counterModes)];
    };

    waitUntil {sleep 2; (((getPosATL _plane) # 2) <= 500) || (isNull _plane) || (!alive _plane)}; // Wait altitude

    // Fail-safe exit
    if ((isNull _plane) || {!alive _plane} || {_plane getVariable ["PIG_CAS_isRTB", false]}) exitWith {_plane setVariable ["PIG_CAS_isEvading", false]};

    if (_threat == vehicle _threat) then {
		(group _threat) ignoreTarget (_plane);
        //(group _threat) forgetTarget (_plane);
	} else {
		(group (gunner _threat)) ignoreTarget (_plane);
        //(group (gunner _threat)) forgetTarget (_plane);
	};

    // Go in the opposite direction of the threat
    private _oppositeDirThreatPos = (_plane getPos [4000, (_plane getDir _threat) + 180]);
    _plane setVariable ["PIG_CAS_retreatPos", _oppositeDirThreatPos];
    private _evadeWp = (group (driver _plane)) addWaypoint [_oppositeDirThreatPos, 0];
    /*
        createMarkerLocal ["PIG_CAS_evadeMarkerPos", _oppositeDirThreatPos];
        "PIG_CAS_evadeMarkerPos" setMarkerTypeLocal "mil_arrow2";
        "PIG_CAS_evadeMarkerPos" setMarkerDirLocal ((_plane getDir _threat) + 180);
        "PIG_CAS_evadeMarkerPos" setMarkerTextLocal "Evade Position and direction";
        "PIG_CAS_evadeMarkerPos" setMarkerColorLocal "colorBLUE";
        (group (driver _plane)) move _oppositeDirThreatPos;
    */

    waitUntil {sleep 2; ((_plane distance2d _oppositeDirThreatPos) < 500) || (isNull _plane) || (!alive _plane)}; // Wait distance
    // Fail-safe exit
    if ((isNull _plane) || {!alive _plane} || {_plane getVariable ["PIG_CAS_isRTB", false]}) exitWith {_plane setVariable ["PIG_CAS_isEvading", false]};
	
	(group(driver _plane)) setBehaviourStrong "CARELESS";
    (group(driver _plane)) setSpeedMode "NORMAL";

    //deleteMarkerLocal "PIG_CAS_threatPos";
    //deleteMarkerLocal "PIG_CAS_evadeMarkerPos";

    _plane setVariable ["PIG_CAS_isBusy", false];
	[_plane, getPosASL _plane, (_plane getVariable "PIG_CAS_planeLoiterRadius")] call PIG_fnc_createLoiterWaypoint; // New loiter position
    _plane setVariable ["PIG_CAS_isEvading", false];
    [_plane] call PIG_fnc_updateCasMenu;
    

    [_plane, "incomingmissile"] call PIG_fnc_planeAddEH; 
    _plane setVariable ["PIG_CAS_retreatPos", nil];
};