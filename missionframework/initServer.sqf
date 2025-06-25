missionNamespace setVariable ["PIG_CAS_inAir", false, true];
missionNamespace setVariable ["PIG_CAS_supportAvailable", false, true];
[] call PIG_fnc_initCas;

addMissionEventHandler ["EntityDeleted", {
	params ["_entity"];
    
    if (_entity in PIG_CAS_planeList) then {
        [] call PIG_fnc_updateCasMenu;; // Update menu
    };
}];