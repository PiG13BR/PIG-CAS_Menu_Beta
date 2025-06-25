/*
    File: fn_monitorFuel.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 08/05/2025
    Update Date: 13/05/2025

    Description:
        Update menu's fuel bar

    Parameter(s):
       _plane - aircraft in the air [OBJECT]
    
    Returns:
        -
*/
params["_plane"];

// ToDo create trigger for this 

while {(!isNull _plane) && (alive _plane) && !(_plane getVariable ["PIG_CAS_isOnBase", false])} do {
    private _fuel = (fuel _plane);

    // Check for low fuel
    if ((_fuel <= PIG_CAS_minimumBingoFuel) && !(_plane getVariable ["PIG_CAS_landed", false]) && !(_plane getVariable ["PIG_CAS_isRTB", false]) && !(_plane getVariable ["PIG_CAS_isOnBase", false])) then {
        _groupID = _plane getVariable "PIG_CAS_pilotGroupID";
        ["PIG_CAS_LowFuel_Notification", [_groupID, _groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers]; // Notification
        [_plane] call PIG_fnc_planeRTB; // Force RTB
        [] call PIG_fnc_updateCasMenu; // Update Menu
    };
    sleep 1;
};


