/*
    File: fn_addActionMenu.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 05/05/2025
    Update Date: 28/06/2025

    Description
        Add action to all players that are have access the cas menu
        Add ability to mark targets
    
    Parameter(s):
        _player - player/caller [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params[["_player", player, [ObjNull]]];
   
// Add EH only for the player that has access to the menu
if (_player in PIG_CAS_callers) then {
    PIG_CAS_InventoryRequiredItems = [];

    if (isMultiplayer) then {
        // Check if the player already has the items
        private _items = assignedItems _player;
        _items = _items apply {toLowerANSI _x};
        private _hasItems = _items arrayIntersect PIG_CAS_requiredItemsAccess;
        if ((count _hasItems) == (count PIG_CAS_requiredItemsAccess)) then {
            PIG_CAS_InventoryRequiredItems = _hasItems;
            // Create action to access menu
            _actionID = _player addAction [
                ["<img size='2' image='a3\modules_f_curator\data\portraitcas_ca.paa'/>", "<t size='1.3'>", "Open CAS Menu","</t>"] joinString "", 
                {[_this # 1] call PIG_fnc_manageCasMenu}
                , nil, 2, true, true, PIG_CAS_shorcutAccess, toString {
                    (alive _originalTarget) // Check if it's alive
                    && {_this == _originalTarget} // Check if the unit whom the action is shown is the same that was added the action
                    // && {isNull (objectParent _originalTarget)} // Check if it's in a vehicle 
                }
            ];
            _player setVariable ["PIG_CAS_menuActionID", _actionID]; // Store ID
        };
    };

     // Fill this array to check if the player has the necessary required items to get access to jet cas menu
    _player addEventHandler ["SlotItemChanged", {
        params ["_unit", "_name", "_slot", "_assigned", "_weapon"];
        // Check assigned item
        if (_assigned) then {
            // Check if the item is in required items array
            if ((toLowerANSI _name) in PIG_CAS_requiredItemsAccess) then {
                PIG_CAS_InventoryRequiredItems pushBackUnique (toLowerANSI _name); // add item to the inventory array. Lowercase.
                PIG_CAS_InventoryRequiredItems sort true; // sort them
                // Check if player has the required items. The two arrays must match
                if (PIG_CAS_InventoryRequiredItems IsEqualTo PIG_CAS_requiredItemsAccess) then {
                    // Create action to access menu
                    _actionID = _unit addAction [
                        ["<img size='2' image='a3\modules_f_curator\data\portraitcas_ca.paa'/>", "<t size='1.3'>", "Open CAS Menu","</t>"] joinString "", 
                        {[_this # 1] call PIG_fnc_manageCasMenu}
                        , nil, 2, true, true, PIG_CAS_shorcutAccess, toString {
                            (alive _originalTarget) // Check if it's alive
                            && {_this == _originalTarget} // Check if the unit whom the action is shown is the same that was added the action
                            // && {isNull (objectParent _originalTarget)} // Check if it's in a vehicle 
                        }
                    ];
                    _unit setVariable ["PIG_CAS_menuActionID", _actionID]; // Store ID
                }
            }
        } else {
            // Find if the removed item is in the array
            private _index = PIG_CAS_InventoryRequiredItems find (toLowerANSI _name);
            if (_index != -1) then { 
                // Remove item and the action
                PIG_CAS_InventoryRequiredItems deleteAt _index; 
                _unit removeAction (_unit getVariable ("PIG_CAS_menuActionID"));
            };
        };
    }];

    // Add ability to mark targets for certains type of supports while the selected aircraft is attacking
    localNamespace setVariable ["PIG_CAS_caller", _player];
    
    private _userActionEH = addUserActionEventHandler ["revealTarget", "Activate", {    
        params ["_activated"];
            
        private _caller = localNamespace getVariable ["PIG_CAS_caller", objNull];
        private _plane = _caller getVariable ["PIG_CAS_callerSelectedPlane", objNull];
        if (isNull _caller || {isNull _plane}) exitWith {}; // Exit on aircraft or caller null
        if !(_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {}; // Exit on aircraft selected not attacking
        //if !(_plane in PIG_CAS_planesAttacking) exitWith {}; // Exit on aircraft selected not attacking
        
        private _supportType = _plane getVariable ["PIG_CAS_attackSupportType", "LASER-GUIDED BOMBS"];
        if !((_supportType == "AIR-TO-GROUND") || (_supportType == "LASER-GUIDED BOMBS")) exitWith {systemChat "Wrong support type for marking targets"}; // Exit on wrong support type for marking targets
        private _laserTarget = objNull;
        // Check for drones
        if (isRemoteControlling _caller) then {_laserTarget = _plane getVariable ["PIG_CAS_laserTarget", objNull]} else {_laserTarget = laserTarget _caller};
        if (isNull _laserTarget) exitWith {systemChat "Laser targetting is needed to mark targets";}; // (_plane setVariable ["PIG_CAS_markedTargets", []])

        private _logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
        //private _logicPos = getPosATL _logic;
        if (_logic distance _laserTarget >= 250) exitWith {systemChat "Cannot mark target, is too far from target position"};
        private _nearEntities = [];
            if (_supportType == "AIR-TO-GROUND") then {
                // Mark only IR targets
                _nearEntities = _laserTarget nearEntities ["LandVehicle", 5] select {((alive _x) && {_x isKindOf "landVehicle"} && {isEngineOn _x} && {((side (driver _plane)) getFriend (side _x)) < 0.6})}
            } else {
                // Mark any valid land entity
                _nearEntities = _laserTarget nearEntities [["LandVehicle", "Air"], 5];
            };

        private _ammoCount = _plane getVariable ["PIG_CAS_attackMagAmmoCount", 0];
        if (_ammoCount isEqualTo 0) exitWith {};
        
        if (count _nearEntities < 1) exitWith {systemChat "No entities nearby to mark as a target."};

        _nearEntities = [_nearEntities, [], {_x distance _laserTarget}, "ASCEND", {alive _x}] call BIS_fnc_sortBy;
        private _nearTarget = _nearEntities # 0;
        private _findIndex = (_plane getVariable ["PIG_CAS_markedTargets", []]) find _nearTarget;
        if (_findIndex == -1) then {
            // Add to the list 
            // systemChat format ["Ammo count: %1, Marked targets: %2", _ammoCount, (count (_plane getVariable ["PIG_CAS_markedTargets", []]))];
            if (_ammoCount <= (count (_plane getVariable ["PIG_CAS_markedTargets", []]))) exitWith {systemChat "Cannot mark target. Limit reached for this munition."}; // Limit will be the rounds
            // systemChat format ["Target marked for %1", (_plane getVariable ["PIG_CAS_pilotGroupID", (groupID(group(driver _plane)))])];
            (_plane getVariable ["PIG_CAS_markedTargets", []]) pushBackUnique _nearTarget;
        } else {
            systemChat format ["Marked target removed for %1", (groupID(group(driver _plane)))];
            // Remove it from the list
            (_plane getVariable ["PIG_CAS_markedTargets", []]) deleteAt _findIndex;
        };

        // Create draw3dIcon
        if (count (_plane getVariable ["PIG_CAS_markedTargets", []]) > 0) then {
            // Don't add more MEH
            if (isNil "PIG_CAS_markTargets_drawMEH") then {
                PIG_CAS_markTargets_drawMEH = addMissionEventHandler ["Draw3D", {
                    _thisArgs params ["_caller"];
                    private _plane = _caller getVariable ["PIG_CAS_callerSelectedPlane", objNull]; // Last selected plane from the menu
                    // Autodeletion
                    if (count PIG_CAS_planesAttacking == 0) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]; PIG_CAS_markTargets_drawMEH = nil}; // Remove it right away if no aircraft is attacking
                    if !(_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {}; // Ignore iterations for non attacking planes
                    if ((_plane getVariable ["PIG_CAS_markedTargets", []]) isEqualTo []) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]; PIG_CAS_markTargets_drawMEH = nil}; // If no targets are marked, remove this MEH
                    //if (!(_plane getVariable ["PIG_CAS_isAttacking", false]) || {(_plane getVariable ["PIG_CAS_markedTargets", []]) isEqualTo []}) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]; PIG_CAS_markTargets_drawMEH = nil};

                    {
                        _markedTargetPos = (getPosVisual _x);
                        _targetATL = (getPosATL _x) # 2;
                        _markedTargetPos set [2, (_targetATL + 1.4)]; // Height offset
                        //_heightOffSet = (getPosATL _x);
                        drawIcon3D ["a3\ui_f\data\igui\cfg\targeting\markedtarget_ca.paa", [0.9,0,0,1], _markedTargetPos, 1.1, 1.4, 0, format ["Marked Target (%1)", _plane getVariable ["PIG_CAS_pilotGroupID", (groupID(group(driver _plane)))]], 1, 0.03, "RobotoCondensed"];
                    }forEach (_plane getVariable ["PIG_CAS_markedTargets", []]);          
                }, [_caller]];
            }
        };
    }];
    /*
    _player addEventHandler ["WeaponChanged", {
        params ["_object", "_oldWeapon", "_newWeapon", "_oldMode", "_newMode", "_oldMuzzle", "_newMuzzle", "_turretIndex"];

        if (!alive _object) exitWith {_object removeEventHandler [_thisEvent, _thisEventHandler]};

        if ((getNumber(configFile >> "cfgWeapons" >> _newWeapon >> "Laser")) > 0) then {
            private _userActionEH = addUserActionEventHandler ["revealTarget", "Activate", {    
                params ["_activated"];
                    
                private _caller = localNamespace getVariable ["PIG_CAS_caller", objNull];
                private _plane = _caller getVariable ["PIG_CAS_callerSelectedPlane", objNull];
                if (isNull _caller || isNull _plane) exitWith {}; // Exit on aircraft or caller null
                if !(_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {}; // Exit on aircraft selected not attacking
                //if !(_plane in PIG_CAS_planesAttacking) exitWith {}; // Exit on aircraft selected not attacking
                
                private _supportType = _plane getVariable ["PIG_CAS_attackSupportType", "LASER-GUIDED BOMBS"];
                if !((_supportType == "AIR-TO-GROUND") || (_supportType == "LASER-GUIDED BOMBS")) exitWith {systemChat "Wrong support type for marking targets"}; // Exit on wrong support type for marking targets
                private _laserTarget = laserTarget _caller;
                if (isNull _laserTarget) exitWith {systemChat "Turn on the laser to mark targets";}; // (_plane setVariable ["PIG_CAS_markedTargets", []])

                private _logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
                //private _logicPos = getPosATL _logic;
                if (_logic distance _laserTarget >= 250) exitWith {systemChat "Cannot mark target, is too far from target position"};
                private _nearEntities = [];
                    if (_supportType == "AIR-TO-GROUND") then {
                        // Mark only IR targets
                        _nearEntities = _laserTarget nearEntities ["LandVehicle", 5] select {((alive _x) && {_x isKindOf "landVehicle"} && {isEngineOn _x} && {((side (driver _plane)) getFriend (side _x)) < 0.6})}
                    } else {
                        // Mark any valid land entity
                        _nearEntities = _laserTarget nearEntities [["LandVehicle", "Air"], 5];
                    };

                private _ammoCount = _plane getVariable ["PIG_CAS_attackMagAmmoCount", 0];
                if (_ammoCount isEqualTo 0) exitWith {};
                
                if (count _nearEntities < 1) exitWith {systemChat "No entities nearby to mark as a target."};

                _nearEntities = [_nearEntities, [], {_x distance _laserTarget}, "ASCEND", {alive _x}] call BIS_fnc_sortBy;
                private _nearTarget = _nearEntities # 0;
                private _findIndex = (_plane getVariable ["PIG_CAS_markedTargets", []]) find _nearTarget;
                if (_findIndex == -1) then {
                    // Add to the list 
                    // systemChat format ["Ammo count: %1, Marked targets: %2", _ammoCount, (count (_plane getVariable ["PIG_CAS_markedTargets", []]))];
                    if (_ammoCount <= (count (_plane getVariable ["PIG_CAS_markedTargets", []]))) exitWith {systemChat "Cannot mark target. Limit reached for this munition."}; // Limit will be the rounds
                    // systemChat format ["Target marked for %1", (_plane getVariable ["PIG_CAS_pilotGroupID", (groupID(group(driver _plane)))])];
                    (_plane getVariable ["PIG_CAS_markedTargets", []]) pushBackUnique _nearTarget;
                } else {
                    systemChat format ["Marked target removed for %1", (groupID(group(driver _plane)))];
                    // Remove it from the list
                    (_plane getVariable ["PIG_CAS_markedTargets", []]) deleteAt _findIndex;
                };

                // Create draw3dIcon
                if (count (_plane getVariable ["PIG_CAS_markedTargets", []]) > 0) then {
                    // Don't add more MEH
                    if (isNil "PIG_CAS_markTargets_drawMEH") then {
                        PIG_CAS_markTargets_drawMEH = addMissionEventHandler ["Draw3D", {
                            _thisArgs params ["_caller"];
                            private _plane = _caller getVariable ["PIG_CAS_callerSelectedPlane", objNull]; // Last selected plane from the menu
                            // Autodeletion
                            if (count PIG_CAS_planesAttacking == 0) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]; PIG_CAS_markTargets_drawMEH = nil}; // Remove it right away if no aircraft is attacking
                            if !(_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {}; // Ignore iterations for non attacking planes
                            if ((_plane getVariable ["PIG_CAS_markedTargets", []]) isEqualTo []) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]; PIG_CAS_markTargets_drawMEH = nil}; // If no targets are marked, remove this MEH
                            //if (!(_plane getVariable ["PIG_CAS_isAttacking", false]) || {(_plane getVariable ["PIG_CAS_markedTargets", []]) isEqualTo []}) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]; PIG_CAS_markTargets_drawMEH = nil};

                            {
                                _markedTargetPos = (getPosVisual _x);
                                _targetATL = (getPosATL _x) # 2;
                                _markedTargetPos set [2, (_targetATL + 1.4)]; // Height offset
                                //_heightOffSet = (getPosATL _x);
                                drawIcon3D ["a3\ui_f\data\igui\cfg\targeting\markedtarget_ca.paa", [0.9,0,0,1], _markedTargetPos, 1.1, 1.4, 0, format ["Marked Target (%1)", _plane getVariable ["PIG_CAS_pilotGroupID", (groupID(group(driver _plane)))]], 1, 0.03, "RobotoCondensed"];
                            }forEach (_plane getVariable ["PIG_CAS_markedTargets", []]);          
                        }, [_caller]];
                    }
                };
            }];
            _object setvariable ["PIG_CAS_callerUserActionEH", ["revealTarget", "Activate", _userActionEH]];
        } else {
            removeUserActionEventHandler (_object getvariable ["PIG_CAS_callerUserActionEH", []]);
            _plane setVariable ["PIG_CAS_markedTargets", []]
        }
    }];
    */
};