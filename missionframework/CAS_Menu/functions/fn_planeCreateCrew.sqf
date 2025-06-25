/*
    File: fn_planeCreateCrew.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 05/06/2025
    Update Date: 17/06/2025

    Description:
        Create crew for the aircraft

    Parameter(s):
       _plane - selected aircraft [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params [["_plane", objNull, [objNull]]];

if ((isNull _plane) || (!alive _plane)) exitWith {};

private _pilotClass = _plane getVariable "PIG_CAS_pilotClass";
private _pilotSide = _plane getVariable "PIG_CAS_pilotSide";
private _pilotGroupID = _plane getVariable "PIG_CAS_pilotGroupID";
private _group = createGroup _pilotSide;
_group setGroupIdGlobal [_pilotGroupID];

private _seats = fullCrew [_plane, "", true];
{
    _checkSeat = _x select 0; // Unit - For empty seat must retun <NULL-object>
	_role = _x select 1; // Role - "driver", "gunner", "turret", "cargo", "commander"

    if !(isNull _checkSeat) then {diag_log format ["[CAS MENU WARNING] %1 in %2 is occupied", _role, _plane]; continue}; // Skip iteration and give a warning

    private _crew = _group createUnit [_pilotClass, getPosWorld _plane, [], 10, "NONE"];
    switch (_role) do {
        case "driver" : {
            _crew assignAsDriver _plane;
            _crew moveInDriver _plane;
        };
        case "gunner" : {
            _crew assignAsGunner _plane;
            _crew moveInGunner _plane;
        };
        case "commander" : {
            _crew assignAsCommander _plane;
            _crew moveInCommander _plane;
        };
    };
    _crew disableAI "TARGET";
    _crew disableAI "AUTOTARGET";
    _crew disableAI "RADIOPROTOCOL";
    _crew setCombatMode "BLUE";
}forEach _seats;

