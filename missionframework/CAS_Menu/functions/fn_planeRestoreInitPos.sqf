/*
    File: fn_planeRestoreInitPos.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 09/06/2025
    Update Date: 21/06/2025

    Description
        Resets the aircraft's starting position and its status after landing
    
    Parameter(s):
        _plane - aircraft that landed [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params[["_plane", objNull, [objNull]]];

if (isNull _plane) exitWith {["[CAS MENU] airplane is null"] call BIS_fnc_error};

// Delete event handlers
_eventHandlers = _plane getVariable ["PIG_CAS_eventHandlers", []];
if (_eventHandlers isNotEqualTo []) then {
    {
        _event = (_x # 0);
        _index = (_x # 1);
        _plane removeEventHandler [_event, _index]
    }forEach _eventHandlers;
    _plane setVariable ["PIG_CAS_eventHandlers", []];
};

_plane allowdamage false;

// Set jet pos
(_plane getVariable ["PIG_CAS_originalJetPos", [[0,0,0], 0]]) params ["_pos", "_dir"];

// Set plane's position
_plane setPosATL _pos;
_plane setDir _dir;

// Attach to logic
private _logic = (_plane getVariable "PIG_CAS_attachedLogic");
_plane attachTo [_logic];
[_plane, true] call PIG_fnc_aircraftFoldingWings;

// Turn engine off
_plane engineOn false;

// Variables
[_plane] call PIG_fnc_planeResetVariables;

// Repair, Rearm and Refuel
[_plane] spawn PIG_fnc_baseServices;
[_plane] call PIG_fnc_updateCasMenu;  // Update menu

// Delete vehicle crew
deleteVehicleCrew _plane;