/*
    File: fn_registerSupport.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 24/04/2025
    Update Date: 07/06/2025

    Description:
        For the selected aircraft, get all magazines and separate them into categories/keys in a hashmap. This hashmap will be used in the menu.
        Some magazines may be in other categories itself. For example, vanilla scalpel can target laser and IR.
        I've put it out these categories finding configs patterns from vanilla and some popular modded aircrafts. So It should work for modded aircraft and its magazines aswell. 
        If doesn't work (misplacement of magazines), it's a really shitty mod config there.

    Parameter(s):
       _plane - selected aircraft in the menu to look for weapons and magazines data [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params[["_plane", objNull, [objNull]]];

// Create/reset hashmap
PIG_jetCas_supports = createHashMapFromArray [
    ["STRAFING RUN", []], // Default main gun
    ["LASER-GUIDED ROCKETS", []], // Laser guided rockets
    ["LASER-GUIDED BOMBS", []], // Laser guided bombs
    ["AIR-TO-GROUND", []], // AGM (IR missiles/bombs)
    ["GP BOMBS", []], // Dumb bombs (e.g. Mk82)
    ["GP ROCKETS", []], // Non-guided rockets
    ["CLUSTER", []], // Clusters
    ["INFRARED AA", []], // Anti-air (IR)
    ["SEAD", []] // Anti-radar
];
[["LASER-GUIDED BOMBS",[["pylonmissile_bomb_gbu12_x1","weapon_gbu12launcher",2,2]]],
["AIR-TO-GROUND",[["pylonrack_missile_agm_02_x1","weapon_agm_65launcher",2,2]]],
["GP BOMBS",[]],["GP ROCKETS",[]],["SEAD",[["pylonrack_missile_harm_x1","weapon_harmlauncher",2,2]]],
["LASER-GUIDED ROCKETS",[]],["INFRARED AA",[["pylonmissile_missile_bim9x_x1","weapon_bim9xlauncher",2,2]]],
["CLUSTER",[]],["STRAFING RUN",[["magazine_fighter01_gun20mm_aa_x450","weapon_fighter_gun20mm_aa",450,450]]]];
_magazinesInfo = (magazinesAllTurrets _plane);

// Find manual configuration
private _getManualCfg = PIG_CAS_manualCfg select {
    _x params ["_varName", "_hashMap"];

    if (_varName isEqualTo _plane) exitWith {_hashMap}; // Return the manual configuration
    false
};

if (_getManualCfg isNotEqualTo []) exitWith {
    // Manual configuration found, exit the function here
    {
        private _key = (_x # 0);
        private _value = (_x # 1);
        if (_value isEqualTo []) then { continue }; // Ignore empty array
        private _replace = PIG_jetCas_supports get _key;
        private _ammoCount = 0;

        // Iterate magazines from manual cfg
        {
            private _magazine = (toLowerANSI _x);
            private _weaponMuzzle = "";
            private _indexFound = -1;
            {
                // Find the magazine in the turrets to get ammo count
                _indexFound = (tolowerANSI (_x # 0)) find _magazine;
                if (_indexFound >= 0) exitWith {_ammoCount = (_x # 2)};
            }forEach _magazinesInfo;
            // If index is still -1, means that no magazines were found in the aircraft pylons
            if (_indexFound == -1) then { diag_log format ["[CAS MENU] %1 not found in the %2, make sure the airplane have it", _magazine, _plane]; continue };
            if (_ammoCount isEqualTo 0) then { continue }; // Ignore empty magazines

            // Get the weapon muzzle
            {
                _magazinesWeapon = getArray(configFile >> "CfgWeapons" >> _x >> "magazines");
                _magazinesWeapon = _magazinesWeapon apply {tolowerANSI _x};
                
                _findIndex = _magazinesWeapon find _magazine;
                if (_findIndex < 0) then { continue };
                _weaponMuzzle = _x;
            } foreach (weapons _plane);

            private _index = _replace pushBack [_magazine];
            (_replace # _index) pushBack (tolowerANSI _weaponMuzzle); // Weapon
            private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count");
           (_replace # _index) pushBack _ammoCount;
           (_replace # _index) pushBack _totalAmmo;
        }forEach _value;
    }forEach _getManualCfg;

    diag_log format ["[CAS MENU] Final hashmap from manual set up: %1", PIG_jetCas_supports];
};

// Automatic configuration
{
    private _magazine = (tolowerANSI (_x # 0));
    private _ammoCount = (_x # 2);
    private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count");
    private _laserBasedAmmo = false;
    private _IRBasedAmmo = false;
    private _seadBasedAmmo = false;
    private _createSubmunition = false;

    if (_ammoCount isEqualTo 0) then {continue}; // Ignore empty magazines

    private _ammo = getText(configFile >> "CfgMagazines" >> _magazine >> "ammo");
    if ("fuel" in (tolowerANSI _ammo)) then {continue}; // Ignore fuel tanks (mods)
    //private _index = _forEachIndex;
    private _weaponMuzzle = "";

    // Get the weapon muzzle
    {
        _magazinesWeapon = getArray(configFile >> "CfgWeapons" >> _x >> "magazines");
        _magazinesWeapon = _magazinesWeapon apply {tolowerANSI _x};
        
        _findIndex = _magazinesWeapon find _magazine;
        if (_findIndex < 0) then { continue };
        _weaponMuzzle = _x;
    } foreach (weapons _plane);

    // IR vs LASER vs SEAD
    if (isClass (configFile >> "CfgAmmo" >> _ammo >> "Components" >> "SensorsManagerComponent" >> "Components")) then {
        _config = [configFile >> "CfgAmmo" >> _ammo >> "Components" >> "SensorsManagerComponent" >> "Components"] call BIS_fnc_returnChildren;
        {
            _value = getText(_config # _forEachIndex >> "componentType");
            switch _value do {
                case "LaserSensorComponent" : {
                    // Can target laser
                    _laserBasedAmmo = true;
                };
                case "IRSensorComponent" : {
                    // Can target IR
                    _IRBasedAmmo = true;
                };
                case "PassiveRadarSensorComponent" : {
                    // Can target radar
                    _seadBasedAmmo = true;
                    
                };
                default {};
            };
        }forEach _config;
    };

    // Submunition
    if ((getArray(configFile >> "CfgAmmo" >> _ammo >> "submunitionAmmo") isNotEqualTo []) || {getText(configFile >> "CfgAmmo" >> _ammo >> "submunitionAmmo") isNotEqualTo ""}) then {
        _createSubmunition = true;
    };

    // Strafing run
    if (((tolowerANSI ((_weaponMuzzle call BIS_fnc_itemType) # 1) == "machinegun") || ((tolowerANSI ((_weaponMuzzle call BIS_fnc_itemType) # 1) == "vehicleweapon")) && (_ammo isKindOf ["BulletBase", configFile >> "CfgAmmo"]))) then {
            private _strafing = PIG_jetCas_supports get "STRAFING RUN"; //_magazine isKindOf ["BulletBase", configFile >> "CfgAmmo"]
           _index = _strafing pushBack [_magazine];
            (_strafing # _index) pushBack (tolowerANSI _weaponMuzzle); // Weapon
            //private _ammoCount = (_x # 2);
            //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count");
           (_strafing # _index) pushBack _ammoCount;
           (_strafing # _index) pushBack _totalAmmo;
           continue // Don't put this in other category
    };

    // AA missiles (short-range missiles/IR missiles) for helicopters
    if ((getNumber(configFile >> "CfgAmmo" >> _ammo >> "airLock") == 2) && _IRBasedAmmo) then {
        private _aa = PIG_jetCas_supports get "INFRARED AA";
        //private _index = _aa pushBack [_magazine];
        //(_aa # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_aa # _index) pushBack _ammoCount;
        //(_aa # _index) pushBack _totalAmmo;
        private _hashMagazines = _aa apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _aa pushBack [_magazine];
            (_aa # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_aa # _index) pushBack _ammoCount;
            (_aa # _index) pushBack _totalAmmo;
        } else {
            private _getAmmoCount = (_aa # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_aa # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_aa # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_aa # _findIndex) set [3, _newAmmoCount];
        };
        continue // Don't put this in other category
    };

    // Bombs (Dumb/General purpose)
    if (!_laserBasedAmmo && !_IRBasedAmmo && !_createSubmunition && (_ammo isKindOf "BombCore") && (getNumber(configFile >> "CfgAmmo" >> _ammo >> "laserLock") == 0)) then {
        private _bombs = PIG_jetCas_supports get "GP BOMBS";
        //private _index = _bombs pushBack [_magazine];
        //(_bombs # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_bombs # _index) pushBack _ammoCount;
        //(_bombs # _index) pushBack _totalAmmo;
        private _hashMagazines = _bombs apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _bombs pushBack [_magazine];
            (_bombs # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_bombs # _index) pushBack _ammoCount;
            (_bombs # _index) pushBack _totalAmmo;
        } else {
            private _getAmmoCount = (_bombs # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_bombs # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_bombs # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_bombs # _findIndex) set [3, _newAmmoCount];
        };
        continue
    };

    // Rockets (Dumb)
    if ((getText(configFile >> "CfgAmmo" >> _ammo >> "warheadName") == "HE") && {getNumber(configFile >> "CfgAmmo" >> _ammo >> "laserLock") == 0} && (!_laserBasedAmmo) && (!_seadBasedAmmo) && (!_IRBasedAmmo) && (getNumber(configFile >> "CfgAmmo" >> _ammo >> "airLock") == 0)) then {
        private _rocketshe = PIG_jetCas_supports get "GP ROCKETS";
        //private _index = _rocketshe pushBack [_magazine];
        //(_rocketshe # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_rocketshe # _index) pushBack _ammoCount;
        //(_rocketshe # _index) pushBack _totalAmmo;
        private _hashMagazines = _rocketshe apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _rocketshe pushBack [_magazine];
            (_rocketshe # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_rocketshe # _index) pushBack _ammoCount;
            (_rocketshe # _index) pushBack _totalAmmo;
        } else {
            private _getAmmoCount = (_rocketshe # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_rocketshe # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_rocketshe # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_rocketshe # _findIndex) set [3, _newAmmoCount];
        };
        continue
    };

    // Rockets (Laser Guided, scalpel)
    if (_laserBasedAmmo && (((getText(configFile >> "CfgAmmo" >> _ammo >> "submunitionAmmo")) isNotEqualTo "") || (((getText(configFile >> "CfgAmmo" >> _ammo >> "submunitionAmmo")) isEqualTo "") && {(_ammo isKindOf "MissileBase") || (((toLowerANSI _ammo) find "scalpel") != -1)})) && ((getNumber(configFile >> "CfgAmmo" >> _ammo >> "laserLock") > 0))) then {
        private _rocketslg = PIG_jetCas_supports get "LASER-GUIDED ROCKETS";
        //private _index = _rocketslg pushBack [_magazine];
        //(_rocketslg # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_rocketslg # _index) pushBack _ammoCount;
        //(_rocketslg # _index) pushBack _totalAmmo;
        private _hashMagazines = _rocketslg apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _rocketslg pushBack [_magazine];
            (_rocketslg # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_rocketslg # _index) pushBack _ammoCount;
            (_rocketslg # _index) pushBack _totalAmmo;
        } else {
            private _getAmmoCount = (_rocketslg # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_rocketslg # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_rocketslg # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_rocketslg # _findIndex) set [3, _newAmmoCount];
        };
        continue
    };

    // Cluster ammo
    // configFile >> "CfgAmmo" >> "BombCluster_03_Ammo_F" >> "submunitionConeType"
    if (_createSubmunition && (_ammo isKindOf "BombCore")  && (getNumber(configFile >> "CfgAmmo" >> _ammo >> "submunitionConeAngle") > 0)) then {
        private _clusters = PIG_jetCas_supports get "CLUSTER";
        //private _index = _clusters pushBack [_magazine];
        //(_clusters # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_clusters # _index) pushBack _ammoCount;
        //(_clusters # _index) pushBack _totalAmmo;
        private _hashMagazines = _cluster apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _cluster pushBack [_magazine];
            (_cluster # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_cluster # _index) pushBack _ammoCount;
            (_cluster # _index) pushBack _totalAmmo;
        } else {
            private _getAmmoCount = (_cluster # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_cluster # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_cluster # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_cluster # _findIndex) set [3, _newAmmoCount];
        };

        //continue
    };

    // AGM/Bombs (IR)
    //&& (isClass (configFile >> "CfgAmmo" >> _ammo >> "TopDown")) && {getNumber(configFile >> "cfgAmmo" >> _ammo >> "laserLock") == 0}
    if (((_IRBasedAmmo) && {getNumber(configFile >> "cfgAmmo" >> _ammo >> "laserLock") == 0}) || {(_IRBasedAmmo) && {getNumber(configFile >> "cfgAmmo" >> _ammo >> "laserLock") == 1}}) then {
        private _agms = PIG_jetCas_supports get "AIR-TO-GROUND";
        //private _index = _agms pushBack [_magazine];
        //(_agms # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_agms # _index) pushBack _ammoCount;
        //(_agms # _index) pushBack _totalAmmo;
        // Check for similar magazines and ignore class name, just add ammo count
        //private _findIndex = -1;
        //private _index = -1;
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        
        private _hashMagazines = _agms apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _agms pushBack [_magazine];
            (_agms # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_agms # _index) pushBack _ammoCount;
            (_agms # _index) pushBack _totalAmmo;
        } else {
            private _getAmmoCount = (_agms # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_agms # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_agms # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_agms # _findIndex) set [3, _newAmmoCount];
        };
    
        //continue 
    };


    /* Rockets AP. It also creates submunitions.
    if (((getText(configFile >> "CfgAmmo" >> _ammo >> "submunitionAmmo")) isNotEqualTo "") && {getText(configFile >> "CfgAmmo" >> _ammo >> "warheadName") == "HE"} && {getNumber(configFile >> "CfgAmmo" >> _ammo >> "laserLock") == 0}) then {
        _rocketsap = PIG_jetCas_supports get "ROCKETS AP";
        _rocketsap pushBackUnique (tolowerANSI _x);
        continue
    };
    */

    // Bomb (LG GBU) 
    if (_laserBasedAmmo && ((_ammo isKindOf "LaserBombCore") || (_ammo isKindOf "ammo_Bomb_LaserGuidedBase") || (isClass (configFile >> "CfgAmmo" >> _ammo >> "Components" >> "SensorsManagerComponent" >> "Components"))) && (_ammo isKindOf "BombCore") && {"LoalAltitude" in (getArray(configFile >> "CfgAmmo" >> _ammo >> "flightProfiles"))}) then {
        private _gbus = PIG_jetCas_supports get "LASER-GUIDED BOMBS";
        //private _index = _gbus pushBack [_magazine];
        //(_gbus # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_gbus # _index) pushBack _ammoCount;
        //(_gbus # _index) pushBack _totalAmmo;
        // Check for similar magazines and ignore class name, just add ammo count
        //private _findIndex = -1;
        //private _index = -1;
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        
        private _hashMagazines = _gbus apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _gbus pushBack [_magazine];
            (_gbus # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_gbus # _index) pushBack _ammoCount;
            (_gbus # _index) pushBack _totalAmmo;
        } else {
            // Add only ammo count
            private _getAmmoCount = (_gbus # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_gbus # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_gbus # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_gbus # _findIndex) set [3, _newAmmoCount];
        };
        continue
    };

    // SEAD
    if (_seadBasedAmmo) then {
        private _sead = PIG_jetCas_supports get "SEAD";
        //private _index = _sead pushBack [_magazine];
        //(_sead # _index) pushBack (tolowerANSI _weaponMuzzle);
        //private _ammoCount = (_x # 2); // Get ammo count
        //private _totalAmmo = getNumber(configFile >> "CfgMagazines" >> _magazine >> "count"); // Get total ammo count for this kind of magazine
        //(_sead # _index) pushBack _ammoCount;
        //(_sead # _index) pushBack _totalAmmo;
        private _hashMagazines = _sead apply {_x # 0};
        private _findIndex = _hashMagazines find _magazine;

        if (_findIndex == -1) then {
            // New magazine, new array
            private _index = _sead pushBack [_magazine];
            (_sead # _index) pushBack (tolowerANSI _weaponMuzzle);
            (_sead # _index) pushBack _ammoCount;
            (_sead # _index) pushBack _totalAmmo;
        } else {
            // Add only ammo count
            private _getAmmoCount = (_sead # _findIndex) # 2;
            private _newAmmoCount = _ammoCount + _getAmmoCount;
            (_sead # _findIndex) set [2, _newAmmoCount];
            private _getTotalAmmoCount = (_sead # _findIndex) # 3;
            private _newTotalAmmoCount = _getTotalAmmoCount + _totalAmmo;
            (_sead # _findIndex) set [3, _newAmmoCount];
        };
        continue
    };
    
    
}forEach _magazinesInfo;

diag_log format ["[CAS MENU] Final hashmap from automatic set up for %2: %1", PIG_jetCas_supports, _plane];

/*
    New categories:
    The same ammunition can be in one or more categories at the same time.
        Example #1: vanilla scalpel (rocket), in configs, can detect IR and laser targets.
        Example #2: vanilla GBU SDB can target laser and IR targets.
    The airstrike will be handled differently for each selected category.

    "STRAFING RUN" -> Main gun
    "ALL AMMUNITIONS" -> Include all ammunition, except main gun
    "LASER-GUIDED BOMBS" -> All laser guided missiles/bombs
    "AIR-TO-GROUND" -> All infrared air-to-ground (AGM/Bombs)
    "INFRARED AA" -> Infrared air-to-air (short-range AA missiles for attacking helicopters)
    "BOMBS GP" -> General purpose bombs and cluster (un-guided)
    "ROCKETS" -> General purpose rockets (un-guided)
    "CLUSTER" -> Cluster bombs (un-guided and guided ones)
*/

/*
[
    [""LASER-GUIDED BOMBS"",[[""pylonrack_bomb_sdb_x4"",""weapon_sdblauncher"",5,5],[""pylonmissile_bomb_gbu12_x1"",""weapon_gbu12launcher"",1,1]]],
    [""AIR-TO-GROUND"",[[""pylonrack_missile_agm_02_x1"",""weapon_agm_65launcher"",2,2],[""pylonrack_bomb_sdb_x4"",""weapon_sdblauncher"",4,4]]],
    [""GP BOMBS"",[]],
    [""GP ROCKETS"",[]],
    [""SEAD"",[[""pylonrack_missile_harm_x1"",""weapon_harmlauncher"",1,1],[""pylonrack_missile_harm_x1"",""weapon_harmlauncher"",1,1]]],
    [""LASER-GUIDED ROCKETS"",[]],
    [""INFRARED AA"",[[""pylonmissile_missile_bim9x_x1"",""weapon_bim9xlauncher"",1,1],[""pylonmissile_missile_bim9x_x1"",""weapon_bim9xlauncher"",1,1]]],
    [""CLUSTER"",[]],
    [""STRAFING RUN"",[[""magazine_fighter01_gun20mm_aa_x450"",""weapon_fighter_gun20mm_aa"",450,450]]]]