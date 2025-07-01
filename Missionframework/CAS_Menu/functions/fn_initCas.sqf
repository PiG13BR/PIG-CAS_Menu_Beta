/*
    File: fn_initCas.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 06/05/2025
    Update Date: 21/06/2025

    Description:
        For the registered aircrafts, set some attributes, event handlers and variables for each one of them.

    Parameter(s):
       -
    
    Returns:
        -
*/

if (!isServer) exitWith {};

if (count PIG_CAS_planeList == 0) exitWith {diag_log "[CAS MENU] No aircraft registered"};

{
    private _plane = (_x # 0);
    private _groupID = (_x # 1);
    private _airportID = (_x # 2);
    private _onCarrier = (_x # 3);

    // Set some attributes
    _plane allowDamage false;
    _plane allowCrewInImmobile true;
    //_plane lockDriver true;

    // Set fuel consumption base on amount of pylons loaded
    private _pylonLoaded = 0;

	// Add the selected pylons loadout
	{
		private _mag = (_x # 3);
        if (_mag isEqualTo "") then { continue };
        _pylonLoaded = _pylonLoaded + 1; // Pylon armed, add to calculate fuel consumption coeficient
	}forEach (getAllPylonsInfo _plane);
	if (_pylonLoaded isNotEqualTo 0) then {
		_plane setFuelConsumptionCoef (_pylonLoaded * PIG_CAS_fuelConsumption);
	};

    // Get countermeasures
    _currentWeapons = weapons _plane;
    _counterMeasures = _currentWeapons select {tolower ((_x call bis_fnc_itemType) select 1) in ["countermeasureslauncher"]};
    _plane setVariable ["PIG_CAS_jetCounterMeasures", _counterMeasures];

    // Attach plane to logic (fix aircraft to the ground)
    private _logic = (_plane getVariable ["PIG_CAS_attachedLogic", objNull]);
    if (isNull _logic) then {
        _logicSide = createGroup sideLogic;
        _logic = _logicSide createUnit ["logic", getPosATL _plane, [], 0, "NONE"];
        _logic setPosATL (getPosATL _plane);
        _logic setDir (getDir _plane);
    };

    _plane attachTo [_logic];

    _plane setVariable ["PIG_CAS_attachedLogic", _logic, true];
    _plane setVariable ["PIG_CAS_pilotGroupID", _groupID, true];
    _plane setVariable ["PIG_CAS_originalJetPos", [getPosATL _plane, direction _plane], true];
    _plane setVariable ["PIG_CAS_pilotGroup", group (driver _plane), true];
    _plane setVariable ["PIG_CAS_pilotClass", typeOf (driver _plane),true];
    _plane setVariable ["PIG_CAS_pilotSide", side (driver _plane), true];
    // Register airport 
    if (_airportID isEqualType 0) then {
        // ID
        _plane setVariable ["PIG_CAS_airportID", _airportID, true];
    } else {
        // Object (dynamic airport)
        private _airportObject = (nearestObjects [getPosATL _plane, [_airportID], 300]) # 0;
        if (isNil "_airportObject") exitWith {["No dynamic airport found near %1", _plane] call bis_fnc_error};
        _plane setVariable ["PIG_CAS_airportID", _airportObject, true];
        if (_onCarrier) then {
            _plane setVariable ["PIG_CAS_planeOnCarrier", true, true];
        } else {
            _plane setVariable ["PIG_CAS_planeOnCarrier", false, true];
        }
    };

    [_plane] call PIG_fnc_planeResetVariables;
    [_plane, true] call PIG_fnc_aircraftFoldingWings; // Fold wings if supported

    // Delete crew
    deleteVehicleCrew _plane;
}forEach PIG_CAS_planeList