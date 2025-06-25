/*
    File: fn_createLoiterWaypoit.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 29/04/2025
    Update Date: 23/06/2025

    Description:
        Create aircraft's loiter waypoint

    Parameter(s):
       _plane - aircraft [OBJECT, defaults to ObjNull]
       _loiterPos - position where the aircraft will loiter [POSITION, defaults to [0,0,0]]
       _loiterRadius - loiter radius [NUMBER, defaults to 2000]
       _loiterAltitude - loiter altitude [NUMBER, defaults to 1500]
    
    Returns:
        -
*/

params[["_plane", objNull, [objNull]], ["_loiterPos", [0,0,0], [[]], [2]], ["_loiterRadius", PIG_CAS_LoiterMinRadius, [0]], ["_loiterAltitude", PIG_CAS_LoiterAltitude, [0]]];

if (isNull _plane) exitWith {};
if (_loiterPos isEqualTo [0,0,0]) then {_loiterPos = getPosASL _plane}; // If no pos was provided, use plane's position

// Remove current waypoints
{deleteWaypoint _x} forEachReversed (wayPoints(group(driver _plane)));

// This commands works better than forcing flyInHeight
_plane flyInHeightASL [
    _loiterAltitude, 
    _loiterAltitude,
    _loiterAltitude
];

(group(driver _plane)) setBehaviour "CARELESS";

_wpLoiter = (group (driver _plane)) addWaypoint [_loiterPos, 0];
_wpLoiter setWaypointType "LOITER";
_wpLoiter setWaypointSpeed "NORMAL";
_wpLoiter setWaypointLoiterType (selectRandom ["CIRCLE", "CIRCLE_L"]);
_wpLoiter setWaypointLoiterRadius _loiterRadius;
_wpLoiter setWaypointLoiterAltitude _loiterAltitude;

// Save loiter position for this aircraft
_plane setVariable ["PIG_CAS_loiterCasPosition", _loiterPos];
_plane setVariable ["PIG_CAS_loiterWaypoint", _wpLoiter];