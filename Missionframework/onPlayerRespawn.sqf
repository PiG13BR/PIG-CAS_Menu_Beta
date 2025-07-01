params ["_newUnit", "_oldUnit", "_respawn", "_respawnDelay"];

// Add action to the player
if (isMultiplayer) then {
    [_newUnit] call PIG_fnc_addActionMenu;
};
