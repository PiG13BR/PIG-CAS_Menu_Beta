/*
    File: fn_updateHealthFuel.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 07/05/2025
    Update Date: 13/05/2025

    Description:
        Update menu's health and fuel bar

    Parameter(s):
       _plane - aircraft selected in the menu [OBJECT]
    
    Returns:
        -
*/
params ["_plane"];

if ((dialog) && ((findDisplay 363) getVariable ["PIG_CAS_dialogOpen", false])) then {
    private _damage = (damage _plane);
    private _health = (1 - _damage);
    private _fuel = (fuel _plane);

    // Health bar
    (displayCtrl 3631900) progressSetPosition _health;
    (displayCtrl 3631900) ctrlSetTextColor [1, 1, 1, 1];
    private _healthPercent = str((ceil(_health * 100))) + "%";
    (displayCtrl 3631900) ctrlSetTooltip _healthPercent;
    if (progressPosition (displayCtrl 3631900) < 0.5) then {
        (displayCtrl 3631900) ctrlSetTextColor [0.9, 0, 0, 1];
    };

    // Fuel bar
    (displayCtrl 3631901) progressSetPosition _fuel;
    (displayCtrl 3631901) ctrlSetTextColor [1, 1, 1, 1];
    private _fuelPercent = str(ceil(_fuel * 100)) + "%";
    (displayCtrl 3631901) ctrlSetTooltip _fuelPercent;
    if (progressPosition (displayCtrl 3631901) >= 0.3 && progressPosition (displayCtrl 3631901) <= 0.5) then {
        (displayCtrl 3631901) ctrlSetTextColor [0.9, 0.5, 0, 1];
    };
    if (progressPosition (displayCtrl 3631901) < 0.3) then {
        (displayCtrl 3631901) ctrlSetTextColor [0.9, 0, 0, 1];
    };
};