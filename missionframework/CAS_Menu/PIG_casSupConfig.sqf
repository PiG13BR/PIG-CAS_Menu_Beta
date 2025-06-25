// --------------------- Access
PIG_CAS_requiredItemsAccess = ["ItemRadio", "ItemMap"]; // [ARRAY] Class names of required items in the inventory to get access to the cas menu.
PIG_CAS_shorcutAccess = "User12"; // [STRING] Key shorcut to open menu (https://community.bistudio.com/wiki/inputAction/actions)

// --------------------- Aircraft
PIG_CAS_minimumBingoFuel = 0.2; // [NUMBER - 0 to 1] Minimal fuel to force plane to RTB. Put this value a little higher if the airbase is far from the AO.
PIG_CAS_fuelConsumption = 0.2; // [NUMBER] Fuel consumption coeficient based on amount of pylons loaded. More pylons loaded with ammunition = more fuel consumption.

// --------------------- Aircraft loiter waypoint
PIG_CAS_LoiterAltitude = 1500; // [NUMBER] Loiter altitude (Fixed altitude of the aircraft in loiter position).
// The player can choose the aircraft loiter's radius between these two values below, by pressing CTRL + Scroll Mouse while an aircraft is selected and on the ground
PIG_CAS_LoiterMinRadius = 2200; // [NUMBER] Loiter minimum radius (in meters). Recommendation: don't put values below 2200. Some aircraft's can't respect loiter's altitude with such lower loiter radius. If you notice that some aircraft keeps getting higher in altitude with loitering, change its position and with a bigger loiter radius!
PIG_CAS_LoiterMaxRadius = 3500; // [NUMBER] Loiter maximus radius (in meters)

// --------------------- Markers
//PIG_CAS_debugMarkers = false; // [BOOL] It will show on map while cas is attacking: cas start position, attack vector, target position, target laser
PIG_CAS_activeCasMarkerColor = "ColorWEST"; // Airplane's marker if active/in air (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_onBaseCasMarkerColor = "ColorUNKNOWN"; // Airplane's marker if on base (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_busyCasMarkerColor = "colorRED"; // Airplane's marker when if busy (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_loiterActiveMarkerColor = "ColorBLUE"; // Active loiter color (airplane is on air and lotering) (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_loiterBaseMarkerColor = "ColorUNKNOWN"; // Selecting a loiter position if aircraft is on base (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)

// --------------------- Repair, Rearm and Refuel
PIG_CAS_defaultBaseRearmDelay = 30; // [NUMBER] Default delay (in seconds) to rearm the aircraft after landed at airbase.
PIG_CAS_defaultBaseRepairDelay = 60; // [NUMBER] Default delay (in seconds) to repair the aircraft after landed at airbase.
PIG_CAS_defaultBaseRefuelDelay = 15; // [NUMBER] Default delay (in seconds) to refuel the aircraft after landed at airbase.
PIG_CAS_baseServicesDelayMultiplier = 2; // [NUMBER] If the aircraft need base logistics (rearm, repair and refuel), use this multiplier to add more time to get airplane ready.

// --------------------- Misc
PIG_CAS_AGMSearchRadius = 250; // [NUMBER] AGM Missiles target search radius. If aircraft is attacking a position with AGM missiles, it will search for IR targets in that area with the defined radius. Keep it a lower value. This is used for the mechanism to guide missiles to the target (https://community.bistudio.com/wiki/setMissileTarget)
PIG_CAS_AAIRSearchRadius = 500; // [NUMBER]
PIG_CAS_airStrikeOnSmoke = [""]; // [ARRAY] Class names of the grenade shell to directly mark target for an airstrike.

// --------------------- Take off and Land. Airports and Dynamic Airports
//PIG_CAS_airportID = 1; // [NUMBER] This is the ID of the island's airport where the planes will take-off/land. More information: https://community.bistudio.com/wiki/Arma:_Airport_IDs
//PIG_CAS_dynamicAirportClass = "DynamicAirport_01_F"; // [STRING] If you're using dynamic airport, place the defined class here. Default: USS Freedom. More information: https://community.bistudio.com/wiki/Arma_3:_Dynamic_Airport_Configuration


// Convert to lowercase characters
PIG_CAS_requiredItemsAccess = PIG_CAS_requiredItemsAccess apply {toLowerANSI _x}; PIG_CAS_requiredItemsAccess sort true;
if (PIG_CAS_LoiterMinRadius < 2200) then {PIG_CAS_LoiterMinRadius = 2200};
if (PIG_CAS_LoiterMaxRadius < PIG_CAS_LoiterMinRadius) then {PIG_CAS_LoiterMaxRadius = PIG_CAS_LoiterMinRadius};