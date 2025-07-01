/*
    File: fn_planeRTB.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 29/04/2025
    Update Date: 11/06/2025

    Description
        Manages the landing of the selected aircraft from the menu
    
    Parameter(s):
        _plane - selected aircraft [OBJECT, defaults to objNull]
    
    Returns:
        Bool - true if succeeded
*/

params[["_plane", objNull, [objNull]]];

if (_plane isEqualTo objNull) exitWith {diag_log "[CAS MENU] Object is null. Cannot RTB."; false};
if (!(_plane getVariable "PIG_CAS_inAir") && (_plane getVariable "PIG_CAS_isBusy")) exitWith {false};

//missionNamespace setVariable ["PIG_CAS_supportAvailable", false];
private _index = PIG_CAS_planesInAir find _plane;
if (_index >= 0) then {PIG_CAS_planesInAir deleteAt _index; publicVariable "PIG_CAS_planesInAir"};

_plane setVariable ["PIG_CAS_isBusy", true];
_plane setVariable ["PIG_CAS_isRTB", true];

private _planeDriver = (driver _plane);
{deleteWaypoint _x}forEachReversed waypoints (group _planeDriver);

// Order to land at designated airport
_plane landAt (_plane getVariable ["PIG_CAS_airportID", 0]); 

_plane addEventHandler ["Engine", {
	params ["_vehicle", "_engineState"];
    if (!_engineState) then {
        _vehicle setVariable ["PIG_CAS_landed", false];
        if (_vehicle getVariable ["PIG_CAS_planeOnCarrier", false]) then { 
            [_vehicle] spawn {
                params["_vehicle"];
                // systemChat format ["Engine off %1", _vehicle];
                sleep 5; // Wait arrest/recovery snap
                [_vehicle] call PIG_fnc_planeRestoreInitPos; 
            }
        } else {
            [_vehicle] call PIG_fnc_planeRestoreInitPos;
        };
        _vehicle removeEventHandler [_thisEvent, _thisEventHandler];
    };
}];

_plane addEventHandler ["Landing", {
	params ["_plane", "_airportID", "_isCarrier"];
    _plane allowDamage false;
    _plane setPilotLight true;
    _plane setCollisionLight true;
    // systemChat format ["%1 is preparing to land", (groupID (group (driver _plane)))];
    if (_isCarrier) then {
        [_plane] spawn BIS_fnc_aircraftTailhook; // 1/20 times, the recovery doesn't work on it's own for unknown reason
    };
    _plane removeEventHandler [_thisEvent, _thisEventHandler];
}];

_plane addEventHandler ["LandedTouchDown", {
	params ["_plane", "_airportID", "_airportObject"];
    _plane setVariable ["PIG_CAS_landed", true];
    // systemChat format ["%1 landed", (groupID (group (driver _plane)))];
    if (_plane getVariable ["PIG_CAS_planeOnCarrier", false]) then {
        [_plane] spawn {
            params["_plane"];
            waitUntil {(speed _plane) < 5};
            // systemChat format ["%1 stopped", (groupID (group (driver _plane)))];
            _plane engineOn false; // Force trigger engine EH
        }
    };
    _plane removeEventHandler [_thisEvent, _thisEventHandler];
}];

true