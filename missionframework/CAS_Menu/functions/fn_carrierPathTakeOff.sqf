/*
    File: fn_carrierPathTakeOff.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 18/05/2025
    Update Date: 22/06/2025

    Description:
        Make aircraft get some speed before going to the loiter position

    Parameter(s):
       _plane - aircraft object [OBJECT, defaults to objNull]
       _distance - distance in meters to get some speed after take off [NUMBER, defaults to 3000]
    
    Returns:
        -
*/

params[
    ["_plane", objNull, [objNull]], 
    ["_distance", 3000, [0]]
];

private _altitude = (((getPosASL _plane) # 2) + 100);
//_plane flyInHeightASL [_altitude, 300, 300];
_plane flyInHeight [_altitude, true];
private _pathPos = (_plane getPos [_distance, (getDir _plane)]);
_pathPos set [2, _altitude];
_wpTakeOff = (group(driver _plane)) addWaypoint [_pathPos, 100];
_wpTakeOff setWaypointBehaviour "CARELESS";
_wpTakeOff setWaypointSpeed "FULL";
localNamespace setVariable ["PIG_CAS_WPTAKEOFF_INDEX", (_wpTakeOff # 1)];

group(driver _plane) addEventHandler ["WaypointComplete", {
	params ["_group", "_waypointIndex"];
    _driver = (units _group) select {(assignedVehicleRole _x) isEqualTo ["driver"]};
    _plane = assignedVehicle (_driver # 0);

	if (_wayPointIndex == (localNamespace getVariable ["PIG_CAS_WPTAKEOFF_INDEX", 0])) then {
        _loiterPos = _plane getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]];
        _loiterRadius = _plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius];
        [_plane, _loiterPos, _loiterRadius] call PIG_fnc_createLoiterWaypoint;
        _group removeEventHandler [_thisEvent, _thisEventHandler];
	}
}];

