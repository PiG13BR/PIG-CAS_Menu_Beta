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

// Error debug
addMissionEventHandler ["ScriptError", {
	params ["_errorText", "_sourceFile", "_lineNumber", "_errorPos", "_content", "_stackTraceOutput"];
    diag_log format ["[CAS MENU ERROR], Text: %1, File: %2, Line: %3, Error position: %4", _errorText, _sourceFile, _lineNumber, _errorPos];
}];
