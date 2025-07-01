/*
    File: fn_registerCaller.sqf
    Author: PiG13BR
    Date: 08/04/2025
    Update date: 24/04/2025

    Description:
        Register players that will have access to the cas menu
        [this] call PIG_fnc_registerCaller

    Parameter(s):
        _caller - 
    
    Returns:
        -
    
*/
if (!isServer) exitWith {};

params [["_caller", player, [objNull]]];

if (_caller isEqualTo objNull) exitWith {["[CAS MENU] Caller is null"] call BIS_fnc_error};

if (isNil "PIG_CAS_callers") then {
    // Create array
    PIG_CAS_callers = [];
};

PIG_CAS_callers pushBackUnique _caller;
publicVariable "PIG_CAS_callers"; // Broadcast to the network