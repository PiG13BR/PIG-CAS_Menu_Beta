/*
    File: fn_getCarrierCatapults.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 02/05/2025
    Update Date: 16/06/2025

    Description:
        Get and return all carrier catapults

    Parameter(s):
       _carrierClass - Carrier class [STRING, defaults to "Land_Carrier_01_base_F" (USS Freedom)]
    
    Returns:
        _catapults - array contaning all catapults [ARRAY]
*/

params[
	["_carrierClass", "Land_Carrier_01_base_F", [""]] // Carrier USS Freedom as default
];


private _arrayClasses = getArray(configFile >> "CfgVehicles" >> _carrierClass >> "multiStructureParts"); // Find structures parts (hulls)
if (_arrayClasses isEqualTo []) then {["No structures found for this classname"] call bis_fnc_error};
_arrayClasses = _arrayClasses apply {_x # 0}; // Only select the hull classes

// Get catapults
private _catapults = [];
{
	private _cfgChildrenArray = ([configFile >> "CfgVehicles" >> _x >> "Catapults"] call BIS_fnc_returnChildren);
	if (_cfgChildrenArray isEqualTo []) then { continue };
	private _availableCatapult = _cfgChildrenArray select {!((str _x) in PIG_CAS_busyCatapults)};
	if (_availableCatapult isEqualTo []) then { continue };
	private _index = _catapults pushBack [_availableCatapult];
    (_catapults # _index) pushBack _x;
}forEach _arrayClasses;

//if (_catapults isEqualTo []) exitWith {["[CAS MENU] No catapults found. This hull does not contain catapults, or possibly a bad config match"] call BIS_fnc_error; _catapults};

_catapults