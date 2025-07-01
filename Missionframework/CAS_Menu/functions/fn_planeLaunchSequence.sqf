/*
    File: fn_planeLaunchSequence.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 17/06/2025
    Update Date: 25/06/2025

    Description:
       Launch sequence for the aircraft

    Parameter(s):
        _plane - aircraft to launch from the carrier [OBJECT, defaults to objNull]
        _hull - carrier's hull [OBJECT, defaults to objNull]
        _memPoint - catapult memory point [STRING, defaults to "pos_catapult_01"]
        _dirOffset - direction offset of the catapult relative to carrier hull direction [NUMBER, defaults to 0]
        _deflectorsArray - hull's deflectors to animate [ARRAY, defaults to []]
        _catapultSelected - config path of the selected catapult [CONFIG PATH, defaults to ""]
    
    Returns
        -

*/
params[["_plane", objNull, [objNull]], ["_hull", objNull, [objNull]], ["_memPoint", "pos_catapult_01", [""]], ["_dirOffset", 0, [0]], ["_deflectorsArray", [], [[]]], ["_catapultSelected", "", [""]]];

if (_memPoint isNotEqualTo "") then {
    _plane setPhysicsCollisionFlag false; // Disable collision
    // Lock to the available catapult
    [_plane, _hull, _memPoint, _dirOffset] spawn PIG_fnc_lockPlaneToCatapult;
    if (_deflectorsArray isNotEqualTo []) then {
        // With deflectors
        [_hull, _deflectorsArray, 10] spawn BIS_fnc_carrier01AnimateDeflectors; // Deflectors up

        sleep 11; // Wait deflectors animation to be completed

        _plane setVariable ["PIG_CAS_catapulted", true];
        // [_plane] call BIS_fnc_aircraftCatapultLaunch; // Use BIS function to launch airplane
        [_plane] call PIG_fnc_aircraftCatapultLaunch; // With small modifications
        
        //_plane doMove (_plane getPos [700, (getDir _plane)]);
        [_plane, 2500] call PIG_fnc_carrierPathTakeOff;
        
        //[_plane, 2500] execVM "carrierTakeOffPath.sqf";
        sleep 5;
        _plane setDamage 0; // Some planes may get its gear damaged, even with allowDamage false
        
        [_hull, _deflectorsArray, 0] spawn BIS_fnc_carrier01AnimateDeflectors; // Deflectors down
    } else {
        // Without deflectors
        sleep 5;
        _plane setVariable ["PIG_CAS_catapulted", true];
        [_plane] call PIG_fnc_aircraftCatapultLaunch; 
        diag_log "[CAS MENU] No deflectors animations found";
    };

    // Remove as a busy catapult
    PIG_CAS_busyCatapults = PIG_CAS_busyCatapults - [_catapultSelected];
    publicVariable "PIG_CAS_busyCatapults";

    _plane setPhysicsCollisionFlag true;
    _plane setVariable ["PIG_CAS_catapulted", false];
} else {
    ["[CAS MENU] No memory point found"] call BIS_fnc_error
};
