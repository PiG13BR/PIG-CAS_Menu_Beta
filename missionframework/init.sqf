// ---------------- CAS MENU
[] call compile preprocessFile "CAS_Menu\PIG_casSupConfig.sqf";
[] call compile preprocessFile "CAS_Menu\PIG_casManualConfig.sqf";

PIG_CAS_planesInAir = [];
PIG_CAS_planesAttacking = [];

//PIG_CAS_callerAddEH = compile preprocessFileLineNumbers "callerAddEH.sqf";

// Singleplayer
if (!isMultiplayer) then {
    [player] call PIG_fnc_addActionMenu;
};