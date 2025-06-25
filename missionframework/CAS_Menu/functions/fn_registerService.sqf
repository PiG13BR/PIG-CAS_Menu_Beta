/*
    File: fn_registerService.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 24/05/2025
    Update Date: 01/06/2025

    Description
        Register certain object to be a service point for the aircraft.
            [this] call PIG_fnc_registerService; // Register an object with all services
            [this, "REPAIR" or "REFUEL" or "REARM"] call PIG_fnc_registerService; // Register an object with just one service

    Parameter(s):
        _vehicle - vehicle that will serve as a service for aircraft [OBJECT, defaults to objNull] 
        _role - service's role, can be "REPAIR", "REFUEL", "REARM" [STRING, defaults to ""]
            - if no role is provided, the object will take all services role instead
    
    Returns:
        -
*/

params[
    ["_vehicle", objNull], 
    ["_role", ""]
];

if (!isServer) exitWith {};
if (isNull _vehicle) exitWith {["[CAS MENU WARNING] Cannot register the service vehicle, object is null"] call BIS_fnc_error};
if (_role isEqualTo "") then {
    _role = ["REPAIR", "REFUEL", "REARM"];
};

if (isNil "PIG_CAS_baseLogistics") then {
    PIG_CAS_baseLogistics = createHashMapFromArray [
        ["REPAIR", []],
        ["REFUEL", []],
        ["REARM", []]
    ];
};

if (_role isEqualType []) then {
    {
        _data = PIG_CAS_baseLogistics get _x;
        _data pushBack _vehicle
    }forEach _role;
} else {
    private _data = PIG_CAS_baseLogistics get _role;
    if (isNil "_data") exitWith {["[CAS MENU WARNING] Wrong role provided for %1. Couldn't register the service", (typeOf _vehicle)] call BIS_fnc_error};
    _data pushBack _vehicle
}