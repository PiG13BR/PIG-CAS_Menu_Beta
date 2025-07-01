// ---------------- CAS MENU
[] call compile preprocessFile "CAS_Menu\PIG_CAS_configuration.sqf";
[] call compile preprocessFile "CAS_Menu\PIG_CAS_supportManualConfig.sqf";

PIG_CAS_planesInAir = [];
PIG_CAS_planesAttacking = [];

// Singleplayer
if (!isMultiplayer) then {
    [player] call PIG_fnc_addActionMenu;
};