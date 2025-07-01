/*
    File: fn_registerAircraft.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 26/04/2025
    Update Date: 28/06/2025

    Description:
        Register aircraft to appears in the cas menu. Call this function in the init of the airplane.
        [this] call PIG_fnc_registerAircraft - default airport ID will be 0, generally the main airport of an island (e.g. Malden's main island airport)
        [this, 1] call PIG_fnc_registerAircraft - 1 is the airport ID (e.g. Malden's Pegasus Air Co. airbase)
        [this, "myDynamicAirport"] call PIG_fnc_registerAircraft - "myAirportObject" is the defined dynamic airport (https://community.bistudio.com/wiki/Arma_3:_Dynamic_Airport_Configuration). 
            To verify if an aircraft can use the carrier to take off and land: aim to the aircraft that you want to check, and execute this code below in the menu debug.
                getNumber(configFile >> "cfgVehicles" >> typeOf CursorObject >> TailHook)
                If returns 1, then this aircraft can use the carrier (Vanilla airplanes: only the F/A-181)

    Parameter(s):
        _plane - aircraft object [OBJECT, defaults to objNull]
        _airportID - airport ID or dynamic airport class - get all airports ID using allAirports (https://community.bistudio.com/wiki/Arma:_Airport_IDs). If the airplane is on a carrier (with a dynamic airport defined), set this to -1 [NUMBER or STRING, defaults to 0]
    
    Returns:
        -
*/

if (!isServer) exitWith {}; // Exit on client

params[
    ["_plane", objNull, [objNull]], 
    ["_airportID", 0, [0, ""]]
];

if (_plane isEqualTo objNull) exitWith {["[CAS MENU] Object is Null. Cannot register the aircraft"] call BIS_fnc_error};

// Check if the aircraft has tailhook in configs
private _tailHook = (getNumber(configFile >> "cfgVehicles" >> typeOf _plane >> "tailHook"));
if ((_airportID isEqualType "") && {_tailHook < 1}) exitWith {["[CAS MENU] %1 has no tail hook on its configuration. Cannot register the aircraft to take off or land from a carrier", (typeOf _plane)] call BIS_fnc_error};

private _onCarrier = false;
// Check if dynamic airport is a carrier
if ((_airportID isEqualType "") && {(getNumber(missionConfigFile >> "CfgVehicles" >> _airportID >> "isCarrier")) > 0}) then {
    _onCarrier = true;
};

if (crew _plane isEqualTo []) then {
    // If plane is empty create crew to get data from it
    createVehicleCrew _plane;
};

// Add jet to the cas list
if (isNil "PIG_CAS_planeList") then {
    // Create array
    PIG_CAS_planeList = [];
};
private _groupID = groupID (group (driver _plane));
PIG_CAS_planeList pushBack [_plane, _groupID, _airportID, _onCarrier];
PIG_CAS_planeList sort true; // Put them in order
publicVariable "PIG_CAS_planeList"; // Broadcast to the network