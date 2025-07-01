/*
    File: fn_baseServices.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 06/05/2025
    Update Date: 09/06/2025

    Description:
        Fix, rearm and refuel aircraft stationary at base, if provided services is near.

    Parameter(s):
       _plane - aircraft to fix [OBJECT]
    
    Returns:
        -
*/

params["_plane"];

if ((isNull _plane) || {!alive _plane}) exitWith {};

_plane setVariable ["PIG_CAS_isReady", false];
_groupID = _plane getVariable "PIG_CAS_pilotGroupID";
["PIG_CAS_Landed_Notification", [_groupID, _groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers];

// Get service list, if provided
private _rearmServices = PIG_CAS_baseLogistics get "REARM";
private _repairServices = PIG_CAS_baseLogistics get "REPAIR";
private _refuelServices = PIG_CAS_baseLogistics get "REFUEL";

if (PIG_CAS_baseServicesDelayMultiplier< 1) then {PIG_CAS_baseServicesDelayMultiplier = 1};

//---------- RE-ARMING
private _nearRearmServices = _rearmServices select {_x distance2d _plane <= 250};
if (count _nearRearmServices > 0) then {
    private _countAmmo = 0;
    private _maxAmmo = 0;
    private _planeAmmo = 0;
    {
        _countAmmo = _countAmmo + (_x select 2);
        _maxAmmo =  _maxAmmo + (getNumber(configFile >> "CfgMagazines" >> (_x select 0) >> "count"));
    } forEach magazinesAllTurrets _plane;

    if (!(_maxAmmo == 0)) then {
        _planeAmmo = _countAmmo/_maxAmmo;
    };

    if (_planeAmmo < 1) then {
        sleep (PIG_CAS_defaultBaseRearmDelay + (PIG_CAS_defaultBaseRearmDelay - (_planeAmmo * PIG_CAS_baseServicesDelayMultiplier)));
        _plane setVehicleAmmoDef 1;
        _plane setVehicleAmmo 1;
    };
} else {
    diag_log format ["[CAS MENU] No rearm service near %1", _plane];
};

//---------- REPAIRING
private _nearRepairServices = _repairServices select {_x distance2d _plane <= 250};
if (count _nearRepairServices > 0) then {
    private _planeHealth = damage _plane;
    if (_planeHealth > 0) then {
        sleep (PIG_CAS_defaultBaseRepairDelay + (_planeHealth * PIG_CAS_baseServicesDelayMultiplier));
        _plane setDamage 0;
    };
} else {
    diag_log format ["[CAS MENU] No repair service near %1", _plane];
};



//---------- REFUELING
private _nearRefuelServices = _refuelServices select {_x distance2d _plane <= 250};
if (count _nearRefuelServices > 0) then {
    _planeFuel = fuel _plane;
    if (_planeFuel < 1) then {
        sleep (PIG_CAS_defaultBaseRefuelDelay + (PIG_CAS_defaultBaseRefuelDelay - (_planeFuel * PIG_CAS_baseServicesDelayMultiplier)));
        _plane setFuel 1;
    };
} else {
    diag_log format ["[CAS MENU] No refuel service near %1", _plane];
};

_plane setVariable ["PIG_CAS_isReady", true];
[] call PIG_fnc_updateCasMenu; // Update Menu
_groupID = _plane getVariable "PIG_CAS_pilotGroupID";

["PIG_CAS_Ready_Notification", [_groupID, _groupID]] remoteExec ["BIS_fnc_showNotification", 0]; // Notification