/*
    File: fn_planeAddEH.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 09/05/2025
    Update Date: 21/06/2025

    Description:
        Add event handler for the aircraft

    Parameter(s):
        _plane - aircraft to add EH [OBJECT, defaults to objNull]
        _event - what event handler should be added [STRING, defaults to "ALL"]
            "killed", "incomingmissile", "getout", "hit", "all"
    
    Returns:
        -
*/
params[["_plane", objNull, [objNull]], ["_event", "all", [""]]];

if (_plane isEqualTo objNull) exitWith {["[CAS MENU] Object is null. Cannot add EH."] call bis_fnc_error};

_event = toLowerANSI _event;

private _planeEvents = _plane getVariable ["PIG_CAS_eventHandlers", []];
if (isNil "_eventHandlers" || {_eventHandlers isEqualTo []}) then {
    _plane setVariable ["PIG_CAS_eventHandlers", []]
};

// Delete related event handlers
if ((_event == "all") && {count _planeEvents > 0}) then {
    {
        _x params ["_eventHandler", "_index"];
        _plane removeEventHandler [_eventHandler, _index]
    }forEach _planeEvents;
    _plane setVariable ["PIG_CAS_eventHandlers", []]
};

if ((_event != "all") && {count _planeEvents > 0}) then {
    {
        _x params ["_eventHandler", "_index"];
        if ((toLowerANSI _event) == _eventHandler) then {
            _plane removeEventHandler [_eventHandler, _index];
            _planeEvents deleteAt _forEachIndex;
        }
    }forEach _planeEvents;
};

if ((_event == "killed") || {_event == "all"}) then {
    // Killed event handler
    _killedEH = _plane addEventHandler ["Killed", {
        params ["_unit", "_killer", "_instigator", "_useEffects"];
        // If killed, remove from the list
        [_unit] remoteExec ["PIG_fnc_updateCasMenu", PIG_CAS_callers];
        _groupID = _unit getVariable ["PIG_CAS_pilotGroupID", (groupID (group (driver _unit)))];
        ["PIG_CAS_Down_Notification", [_groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
        private _eHandlers = _unit getVariable ["PIG_CAS_eventHandlers", []];
        if (_eHandlers isNotEqualTo []) then {
            {
                _event = (_x # 0);
                _index = (_x # 1);
                //diag_log format ["[CAS MENU EH DELETION] Event: %1, Index: %2", _event, _index];
                _unit removeEventHandler [_event, _index]
            }forEach _eHandlers;
            _unit setVariable ["PIG_CAS_eventHandlers", nil];
        };
    }];

    if (isNull (driver _plane)) exitWith {};

    (driver _plane) addEventHandler ["Killed", {
        params ["_unit", "_killer", "_instigator", "_useEffects"];
        if ((vehicle _unit != _unit) && {count crew (vehicle _unit) == 0}) then {(vehicle _unit) setDamage 1}; // Destroy aircraft
        _unit removeEventHandler [_thisEvent, _thisEventHandler];
    }];

    (_plane getVariable ["PIG_CAS_eventHandlers", []]) pushBack ["Killed", _killedEH];
};

if ((_event == "fuel") || {_event == "all"}) then {
    // Monitor fuel
    _fuelEH = _plane addEventHandler ["Fuel", {
        params ["_vehicle", "_hasFuel"];
        if !(_hasFuel) then {
            if ((_vehicle getVariable ["PIG_CAS_isRTB", false]) && (_vehicle getVariable ["PIG_CAS_landed", false]) && (isTouchingGround _vehicle)) then {
                // If aircraft landed and run out fuel to taxi, give it a little to keep going
                [_vehicle, 0.1] remoteExec ["setFuel"];
            } else {
                if (count (crew _vehicle) == 0) exitWith {_vehicle removeEventHandler [_thisEvent, _thisEventHandler]};
                _groupID = _vehicle getVariable ["PIG_CAS_pilotGroupID", (groupID (group (driver _vehicle)))];
                ["PIG_CAS_OutOfFuel_Notification", [_groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
                _vehicle spawn {
                    waitUntil {sleep 0.01; isTouchingGround _this};
                    _this setDamage 1; // Explodes aircraft on ground
                };
                _vehicle removeEventHandler [_thisEvent, _thisEventHandler];
            };
        };
    }];

    _plane getVariable ["PIG_CAS_eventHandlers", []] pushBack ["Fuel", _fuelEH];
};



if ((_event == "getout") || {_event == "all"}) then {
    // Get out EH
    _getOutEH = _plane addEventHandler ["GetOut", {
        params ["_vehicle", "_role", "_unit", "_turret", "_isEject"];
        if !(_plane getVariable ["PIG_CAS_isOnBase", false]) then {
            _unit setDamage 1; // Kill pilot
            if (count (crew _vehicle) == 0) then {_vehicle setDamage 1}; // Destroy aircraft
            _unit removeEventHandler [_thisEvent, _thisEventHandler];
        };
    }];

    _plane getVariable ["PIG_CAS_eventHandlers", []] pushBack ["GetOut", _getOutEH];
};

// Incoming missile warning
if ((_event == "incomingmissile") || {_event == "ALL"}) then {
    _IncomingMissileEH = _plane addEventHandler ["IncomingMissile", {
        params ["_target", "_ammo", "_vehicle", "_instigator", "_missile"];
        if ((_target getVariable ["PIG_CAS_isRTB", false]) && (_target getVariable ["PIG_CAS_isOnBase", false])) exitWith {};
        if (((getNumber(configFile >> "cfgAmmo" >> _ammo >> "airLock")) > 0) && {(local _target) && (isDamageAllowed _target)}) then {
            // Try to evade missile
            [_target, _vehicle] call PIG_fnc_evasiveManeuver;
            // Notification
            _groupID = _target getVariable ["PIG_CAS_pilotGroupID", (groupID (group (driver _target)))];
            ["PIG_CAS_Attacked_Notification", [_groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
            _target removeEventHandler [_thisEvent, _thisEventHandler]; // Fire one time
        };
    }];

    _plane getVariable ["PIG_CAS_eventHandlers", []] pushBack ["IncomingMissile", _IncomingMissileEH];
};

// Monitor damage
if ((_event == "hit") || {_event == "ALL"}) then {
    _hitEH = _plane addEventHandler ["HitPart", {
        (_this select 0) params ["_target", "_shooter", "_projectile", "_position", "_velocity", "_selection", "_ammo", "_vector", "_radius", "_surfaceType", "_isDirect", "_instigator"];

        _ammo = (_ammo # 4);
        // diag_log format ["isDirect: %1, airLock < 2: %2, isKindOf 'BulletBase': %3, selection: %4", _isDirect, (getNumber(configFile >> "cfgAmmo" >> _ammo >> "airLock") < 2), ((_ammo) isKindOf "BulletBase"), _selection];
        if (_isDirect && (getNumber(configFile >> "cfgAmmo" >> _ammo >> "airLock") < 2) && ((_ammo) isKindOf "BulletBase")) then {
            // Only direct fire
            private _groupID = _target getVariable ["PIG_CAS_pilotGroupID", (groupID (group (driver _vehicle)))];
            // Notify caller
            ["PIG_CAS_Attacked_Notification", [(groupID (group (driver _target))), (groupID (group (driver _target)))]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];
            _target removeEventHandler [_thisEvent, _thisEventHandler]; // Fire one time
            _target spawn {
                sleep 30; // Call it again later
                if (!alive _this) exitWith {};
                [_this, "hit"] call PIG_fnc_planeAddEH;
                (_plane getVariable ["PIG_CAS_eventHandlers", []]) pushBack ["IncomingMissile", _hitEH];
            };    
        };

        private _index = -1;
        {
            _index = ["hitengine", "hitfuel", "hitavionics", "hithull"] find _x;
            if (_index >= 0) exitWith {
                if (_target getHitPointDamage _x >= 0.5) then {
                    private _isRTB = [_unit] call PIG_fnc_planeRTB; // Force RTB
                    if (_isRTB) then {
                        [_target] call PIG_fnc_updateCasMenu; // Update Menu
                        private _groupID = _unit getVariable "PIG_CAS_pilotGroupID";
                        ["PIG_CAS_Damaged_Notification", [_groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers]; // Notification
                        _unit removeEventHandler [_thisEvent, _thisEventHandler]; // Kill EH
                    }
                };
            };
        }forEach _selection;
    }];

    _plane getVariable ["PIG_CAS_eventHandlers", []] pushBack ["hit", _hitEH];
};


//_plane setVariable ["PIG_CAS_eventHandlers", [["Killed", _killedEH], ["Fuel", _fuelEH], ["GetOut", _getOutEH], ["IncomingMissile",_IncomingMissileEH], ["HitPart", _hitEH]]];