// --------------------- Access
PIG_CAS_requiredItemsAccess = ["ItemRadio", "ItemMap"]; // [ARRAY] Class names of required items in the inventory to get access to the cas menu.
PIG_CAS_shorcutAccess = "User12"; // [STRING] Key shorcut to open menu (https://community.bistudio.com/wiki/inputAction/actions)

// --------------------- Aircraft
PIG_CAS_minimumBingoFuel = 0.2; // [NUMBER - 0 to 1] Minimal fuel to force plane to RTB. Put this value a little higher if the airbase is far away from the AO.
PIG_CAS_fuelConsumption = 0.2; // [NUMBER] Fuel consumption coeficient based on amount of pylons loaded. More pylons loaded with ammunition = more fuel consumption.

// --------------------- Aircraft loiter waypoint
PIG_CAS_LoiterAltitude = 1500; // [NUMBER] Loiter altitude (Fixed altitude of the aircraft in loiter position).
PIG_CAS_LoiterMinRadius = 3000; // [NUMBER] Loiter minimum radius (in meters). Don't lower this value, some modded aircrafts may not respect its loiter's altitude.
PIG_CAS_LoiterMaxRadius = 5000; // [NUMBER] Loiter maximus radius (in meters).

// --------------------- Markers
PIG_CAS_activeCasMarkerColor = "ColorWEST"; // Airplane's marker if active/in air (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_onBaseCasMarkerColor = "ColorUNKNOWN"; // Airplane's marker if on base (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_busyCasMarkerColor = "colorRED"; // Airplane's marker when it's busy (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_loiterActiveMarkerColor = "ColorBLUE"; // Active loiter color (airplane is on air and lotering) (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)
PIG_CAS_loiterBaseMarkerColor = "ColorUNKNOWN"; // Selecting a loiter position if aircraft is on base (https://community.bohemia.net/wiki/Arma_3:_CfgMarkerColors)

// --------------------- Repair, Rearm and Refuel
PIG_CAS_defaultBaseRearmDelay = 30; // [NUMBER] Default delay (in seconds) to rearm the aircraft after landed at airbase.
PIG_CAS_defaultBaseRepairDelay = 60; // [NUMBER] Default delay (in seconds) to repair the aircraft after landed at airbase.
PIG_CAS_defaultBaseRefuelDelay = 15; // [NUMBER] Default delay (in seconds) to refuel the aircraft after landed at airbase.
PIG_CAS_baseServicesDelayMultiplier = 2; // [NUMBER] If the aircraft need base logistics (rearm, repair and refuel), use this multiplier to add more time to get airplane ready.

// --------------------- Misc
PIG_CAS_AGMSearchRadius = 250; // [NUMBER] AGM Missiles target search radius. If aircraft is attacking a position with AGM missiles, it will search for IR targets in that area with the defined radius. Keep it a lower value. This is used for the mechanism to guide missiles to the target (https://community.bistudio.com/wiki/setMissileTarget)
PIG_CAS_AAIRSearchRadius = 500; // [NUMBER] Infrared air-to-air missile target search radius. Designed to find helicopters flying in the radius area.
PIG_CAS_airStrikeOnSmoke = [""]; // [ARRAY] Class names of the grenade shell to directly mark target for an airstrike.

// Convert to lowercase characters
PIG_CAS_requiredItemsAccess = PIG_CAS_requiredItemsAccess apply {toLowerANSI _x}; PIG_CAS_requiredItemsAccess sort true;
if (PIG_CAS_LoiterMinRadius < 2200) then {PIG_CAS_LoiterMinRadius = 2200};
if (PIG_CAS_LoiterMaxRadius < PIG_CAS_LoiterMinRadius) then {PIG_CAS_LoiterMaxRadius = PIG_CAS_LoiterMinRadius};