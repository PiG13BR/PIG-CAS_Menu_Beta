/*
    File: fn_planeResetVariables.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 09/06/2025
    Update Date: 21/06/2025

    Description:
        Set/reset defaults values for the aircraft's init variables

    Parameter(s):
       _plane - aircraft object [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params[["_plane", objNull, [objNull]]];

if (isNull _plane) exitWith {["[CAS MENU] aircraft is null"] call BIS_fnc_error};

// Misc variables
_plane setVariable ["PIG_CAS_eventHandlers", [], true];
_plane setVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius, true];
_plane setVariable ["PIG_CAS_loiterCasPosition", [0,0,0], true];
_plane setVariable ["PIG_CAS_loiterWaypoint", [], true];

// Actions
_plane setVariable ["PIG_CAS_isOnBase", true, true];
_plane setVariable ["PIG_CAS_isReady", true, true];
_plane setVariable ["PIG_CAS_catapulted", false, true];
_plane setVariable ["PIG_CAS_isTakingOff", false, true];
_plane setVariable ["PIG_CAS_isBusy", false, true];
_plane setVariable ["PIG_CAS_isAttacking", false,true];
_plane setVariable ["PIG_CAS_isRTB", false, true];
_plane setVariable ["PIG_CAS_landed", false, true];
_plane setVariable ["PIG_CAS_isEvading", false, true];