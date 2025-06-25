/*
    File: fn_manageCasMenu.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 24/04/2025
    Update Date: 25/06/2025

    Description:
        Manages the display of the cas menu and its control

    Parameter(s):
       _caller - who open the menu [OBJECT, defaults to player]
    
    Returns:
        -
*/

createDialog "PIG_RscJetCasMenu";

params[["_caller", player, [objNull]]];

if !((findDisplay 363) getVariable ["PIG_CAS_dialogOpen", false]) exitWith {systemChat "Someone is using it"; closeDialog 2};
(findDisplay 363) setVariable ["PIG_CAS_supportCaller", _caller];

// Disable all buttons as default
ctrlEnable [3631600, false]; // Disable confirm button
ctrlEnable [3631601, false]; // Disable RTB button
ctrlEnable [3631602, false]; // Disable RTB button

// Get the aircraft list
PIG_CAS_availablePlanes = PIG_CAS_planeList select {(!isNull (_x # 0)) && {alive (_x # 0)} && {(_x # 0) isKindOf "Plane"}}; // Select only alive aircrafts

// Fill the plane's listbox
{
	_type = typeOf (_x # 0); // Get jet type
    _groupID = (_x # 1); // Get group ID
    private _name = getText(configFile >> "CfgVehicles" >> _type >> "displayName"); // Get jet's display name
    _name = _name + " " + "(" + _groupID + ")"; // Update with the group ID 
    lbAdd [3632100, _name];
}forEach PIG_CAS_availablePlanes;

// Create local markers
[] call PIG_fnc_createMenuMarkers;
"PIG_CAS_callerMarker" setMarkerPosLocal (getPosASL _caller);
"PIG_CAS_callerMarker" setMarkerTextLocal (name _caller);

// Markers functions
PIG_CAS_fnc_loiterPosMarker = {
    params["_plane", "_loiterPos", "_loiterRadius", "_color"];
    "PIG_CAS_marker_loiterPos" setMarkerPosLocal _loiterPos;
    "PIG_CAS_marker_loiterPos" setMarkerColorLocal _color;

    //_loiterRadius = _plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius];
    "PIG_CAS_marker_loiterPosEllipse" setMarkerSizeLocal [_loiterRadius, _loiterRadius];
    "PIG_CAS_marker_loiterPosEllipse" setMarkerPosLocal _loiterPos;
    "PIG_CAS_marker_loiterPosEllipse" setMarkerColorLocal _color;
    _plane setVariable ["PIG_CAS_planeLoiterRadius", _loiterRadius];
};

PIG_CAS_fnc_resetAttackMarkers = {
    "PIG_CAS_marker_strikePos" setMarkerPosLocal [99999,99999,0];
    "PIG_CAS_marker_strikeDir" setMarkerPosLocal [99999,99999,0];
    "PIG_CAS_marker_targetPosEllipse" setMarkerPosLocal [99999,99999,0];
    "PIG_CAS_seadMovePos" setMarkerPosLocal [99999,99999,0];
};

PIG_CAS_fnc_resetLoiterMarkers = {
    "PIG_CAS_marker_loiterPos" setMarkerPosLocal [99999,99999,0];
    "PIG_CAS_marker_loiterPosEllipse" setMarkerPosLocal [99999,99999,0];
};

// Selecting aircraft in the first listbox
(displayCtrl 3632100) ctrlAddEventHandler ["LBSelChanged", {
    params ["_control", "_lbCurSel", "_lbSelection"];

    lbClear 3632101;
    lbClear 3632102;
    lbSetCurSel [3632101, -1];
    lbSetCurSel [3632102, -1];

    // Get data from the selection
    _plane = ((PIG_CAS_availablePlanes select _lbCurSel) # 0); // It's the same index, logically
    //if (!alive _plane) exitWith {[_plane] call PIG_fnc_updateCasMenu;};

    if (isNull ((findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull]) || {((findDisplay 363) getVariable "PIG_CAS_planeObject") != _plane}) then {
        // Save airplane object into this variable
        (findDisplay 363) setVariable ["PIG_CAS_planeObject", _plane];
        private _caller = (findDisplay 363) getVariable ["PIG_CAS_supportCaller", objNull];
        _caller setVariable ["PIG_CAS_callerSelectedPlane", _plane];

        // Map focus when selecting aircraft
        (displayCtrl 36351) ctrlMapAnimAdd [1, 0.5, getPosASL _plane];
        ctrlMapAnimCommit (displayCtrl 36351);
    };

    [_plane] call PIG_fnc_registerSupport; // Collect all ammunition data. Register them to a hashmap.

    // Camera change if on
    _caller = (findDisplay 363) getVariable ["PIG_CAS_supportCaller", player];
    _camera = _caller getVariable ["PIG_CAS_camera", objNull];
    if (!isNull _camera || ( cbChecked (displayCtrl 3632800))) then {
        [_plane, _caller, true] call PIG_fnc_planeCamera;
    };

    [] call PIG_CAS_fnc_resetAttackMarkers;
    (findDisplay 363) setvariable ["PIG_CAS_SelectedKey", nil]; // Clear key variable

    [_plane] call PIG_fnc_updateCasMenu;
    [_plane] call PIG_fnc_updateHealthFuel;
    (displayCtrl 3631902) ctrlSetText "N/A"; // Ammo count text
    (findDisplay 363) setVariable ["PIG_CAS_loiterCasPosition", nil];

}];

// Selecting armament
(displayCtrl 3632101) ctrlAddEventHandler ["LBSelChanged", {
    params ["_control", "_lbCurSel", "_lbSelection"];
    if (_lbCurSel == -1) exitWith {};

    lbClear 3632102;
    lbSetCurSel [3632102, -1];

    // Get data from the selection
    _data = lbData [3632101, _lbCurSel];
    (findDisplay 363) setvariable ["PIG_CAS_SelectedKey", _data];
    // Get key from hashmap
    _hashData = (PIG_jetCas_supports get _data);
    // Fill the third list box with available magazines
    {
        _mag = (_x # 0);
        _name = getText(configFile >> "cfgMagazines" >> _mag >> "displayName");
        _toolTip = getText(configFile >> "cfgMagazines" >> _mag >> "descriptionShort");
        if (_name isEqualTo "") then { if (_data == "STRAFING RUN") then {_name = "Main Gun"} else {_name = _mag} };
        //if (data == "AIR-TO-GROUND") then { _name == "All available magazines"; _toolTip = "It will fire all available ammunition to destroy as many targets as posible"};
        lbAdd [3632102, _name];
        lbSetData [3632102, _forEachIndex, str _x]; // Save the array [magazine, weapon] into a string
        lbSetTooltip [3632102, _forEachIndex, _toolTip]
    }forEach _hashData;
    
    //(displayCtrl 3631902) progressSetPosition 0; // Reset ammo count bar
    (displayCtrl 3631902) ctrlSetText "N/A";

    [] call PIG_CAS_fnc_resetAttackMarkers;
    (findDisplay 363) setVariable ["PIG_CAS_MagazineSelection", nil]; // Clear magazine variable

    ctrlEnable [3631600, false]; // Disable confirm button
}];

// Selecting magazines
(displayCtrl 3632102) ctrlAddEventHandler ["LBSelChanged", {
    params ["_control", "_lbCurSel", "_lbSelection"];
    if (_lbCurSel == -1) exitWith {};

    // Get data from the selection
    _dataString = lbData [3632102, _lbCurSel];
    _data = parseSimpleArray _dataString; // Remove strings
    (findDisplay 363) setVariable ["PIG_CAS_MagazineSelection", _data];
    
    // Ammo count bar
    _ammoCount = _data # 2;
    (findDisplay 363) setVariable ["PIG_CAS_magazineAmmoCount", _ammoCount];
    // _totalAmmo = _data # 3;
    //_count = (_ammoCount / _totalAmmo);

    /* RscProgress
    (displayCtrl 3631902) progressSetPosition _count;
    (displayCtrl 3631902) ctrlSetTextColor [1, 1, 1, 1];
    if (progressPosition (displayCtrl 3631902) < 0.5) then {
        (displayCtrl 3631902) ctrlSetTextColor [0.9, 0, 0, 1];
    };
    */
    (displayCtrl 3631902) ctrlSetText (str _ammoCount);
}];

// Selecting position to attack
(displayCtrl 36351) ctrlAddEventHandler ["MouseButtonDown", { 
	params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    _plane = ((findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull]);
    if (_plane isEqualTo objNull) exitWith {};

    if (_plane getVariable ["PIG_CAS_isOnBase", false]) exitWith {}; // Exit on airplane on base
    if (_plane getVariable ["PIG_CAS_isBusy", false]) exitWith {}; // Exit on busy aircraft
    if (((findDisplay 363) getvariable ["PIG_CAS_SelectedKey", ""]) isEqualTo "") exitWith {}; // Exit on non selected key
    if (((findDisplay 363) getVariable ["PIG_CAS_MagazineSelection", ""]) isEqualTo "") exitWith {}; // Exit on non selected magazine 

    getMousePosition params ["_mouseX", "_mouseY"];

    private _targetPos = (_displayOrControl ctrlMapScreenToWorld [_mouseX, _mouseY]);
    
    // Selecting position to attack
    if (_button == 0) then {
        // Left click
        _displayOrControl setVariable ["PIG_CAS_MouseButtonDown", true];
        // To select target position.
        (findDisplay 363) setVariable ["PIG_CAS_airStrikePos", _targetPos];
        private _key = ((findDisplay 363) getvariable ["PIG_CAS_SelectedKey", ""]);

        if (_key isEqualTo "SEAD") then {
            "PIG_CAS_seadMovePos" setMarkerPosLocal _targetPos;
            (findDisplay 363) setVariable ["PIG_CAS_airStrikeDir", (_plane getDir (markerPos "PIG_CAS_seadMovePos"))];
        } else {
            "PIG_CAS_marker_strikePos" setMarkerTextLocal "Target Position";
            "PIG_CAS_marker_strikePos" setMarkerPosLocal _targetPos;
            
            //"PIG_CAS_marker_strikeDir" setMarkerPosLocal (_targetPos getPos [125, ((findDisplay 363) getVariable ["PIG_CAS_airStrikeDir", 0])]);
            if (_key isEqualTo "STRAFING RUN" || {_key isEqualTo "CLUSTER"}) then {
                private _targetLastDir = ((findDisplay 363) getVariable ["PIG_CAS_airStrikeDir", 0]) - 180;
                "PIG_CAS_marker_strikeDir" setMarkerPosLocal (_targetPos getPos [125, _targetLastDir]);
                "PIG_CAS_marker_strikeDir" setMarkerDirLocal (_targetLastDir - 180);
            }
        };

        switch _key do {
            case "AIR-TO-GROUND" : {
                "PIG_CAS_marker_targetPosEllipse" setMarkerShapeLocal "ELLIPSE";
                "PIG_CAS_marker_targetPosEllipse" setMarkerBrushLocal "Border";
                "PIG_CAS_marker_targetPosEllipse" setMarkerSizeLocal [PIG_CAS_AGMSearchRadius, PIG_CAS_AGMSearchRadius];
                "PIG_CAS_marker_targetPosEllipse" setMarkerPosLocal _targetPos;
                "PIG_CAS_marker_strikePos" setMarkerTextLocal "AGM Radius";
            };
            case "INFRARED AA" : {
                "PIG_CAS_marker_targetPosEllipse" setMarkerShapeLocal "ELLIPSE";
                "PIG_CAS_marker_targetPosEllipse" setMarkerBrushLocal "Border";
                "PIG_CAS_marker_targetPosEllipse" setMarkerSizeLocal [PIG_CAS_AAIRSearchRadius, PIG_CAS_AAIRSearchRadius];
                "PIG_CAS_marker_targetPosEllipse" setMarkerPosLocal _targetPos;
                "PIG_CAS_marker_strikePos" setMarkerTextLocal "AA Radius";
            };
            default {"PIG_CAS_marker_targetPosEllipse" setMarkerPosLocal [99999,99999,0]}
        };
        /*
        if ((_key == "AIR-TO-GROUND") || (_key == "AA")) then {
                "PIG_CAS_marker_targetPosEllipse" setMarkerShapeLocal "ELLIPSE";
                "PIG_CAS_marker_targetPosEllipse" setMarkerBrushLocal "Border";
                "PIG_CAS_marker_targetPosEllipse" setMarkerSizeLocal [PIG_CAS_AGMSearchRadius, PIG_CAS_AGMSearchRadius];
                "PIG_CAS_marker_targetPosEllipse" setMarkerPosLocal _targetPos;
                "PIG_CAS_marker_strikePos" setMarkerTextLocal "AGM Radius";
        } else {
            deleteMarkerLocal "PIG_CAS_marker_targetPosEllipse"; // Delete if created
        };
        */
        if (((lbCurSel (displayCtrl 3632101)) > -1) && {(lbCurSel (displayCtrl 3632102)) > -1}) then {
            ctrlEnable [3631600, true];
        } else {
            ctrlEnable [3631600, false];
        }
        
    };
}];

// Mouse moving EH (map) for setting attack direction
(displayCtrl 36351) ctrlAddEventHandler ["MouseMoving",{
	params ["_control", "_xPos", "_yPos", "_mouseOver"];
    
    private _key = ((findDisplay 363) getvariable ["PIG_CAS_SelectedKey", ""]);

    _mapSign = ctrlMapMouseOver _control;
    _control setVariable ["PIG_CAS_mapMarkerSign", ""];
    // Get map marker
    if ((_mapSign # 0) isEqualTo "marker") then {_control setVariable ["PIG_CAS_mapMarkerSign", (_mapSign # 1)]};
    
    if !(_control getVariable ["PIG_CAS_MouseButtonDown", false]) exitWith {}; // Continue only if the player is pressing mouse button down
    if (_key isEqualTo "SEAD") exitWith {};
    if ((_key isNotEqualTo "STRAFING RUN") && {_key isNotEqualTo "CLUSTER"}) exitWith {};

    getMousePosition params ["_mouseX", "_mouseY"];

    _airStrikePos = (findDisplay 363) getVariable ["PIG_CAS_airStrikePos", [0,0,0]];
    if (_airStrikePos isEqualTo [0,0,0]) exitWith {};

    _attackDir = _airStrikePos getDir (_control ctrlMapScreenToWorld [_mouseX, _mouseY]);

    // systemChat format ["Direction to target position: %1", _attackDir];
    // Markers
    "PIG_CAS_marker_strikeDir" setMarkerPosLocal (_airStrikePos getPos [125, _attackDir - 180]);
    "PIG_CAS_marker_strikeDir" setMarkerDirLocal ((markerPos "PIG_CAS_marker_strikePos") getDir (markerPos "PIG_CAS_marker_strikeDir")) - 180;
    "PIG_CAS_marker_strikeDir" setMarkerTextLocal ((str round(_attackDir)) + "º");

    (findDisplay 363) setVariable ["PIG_CAS_airStrikeDir", _attackDir];

}];

// Grid button (zoom in grid position with edit box)
(displayCtrl 3631603) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];

    _grid = ctrlText 3631400;
    _plane = ((findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull]);

    _mapPos = ((_grid call BIS_fnc_gridToPos) # 0); // Get position (it's not the middle of the grid)
    _gridSize = ((_grid call BIS_fnc_gridToPos) # 1); // Get width/height of the grid. Use this to find the middle position of the grid
    _gridWidth = _gridSize # 0;
    _gridHeight = _gridSize # 1;
    _mapPosX = ((_mapPos # 0) + (_gridWidth/2)); // position + half of the size of the grid = middle of the grid
    _mapPosY = ((_mapPos # 1) + (_gridHeight/2));

    "PIG_CAS_marker_gridPoint" setMarkerPosLocal [_mapPosX, _mapPosY, 0];
    "PIG_CAS_marker_gridPoint" setMarkerTextLocal format ["%1", _grid];

    // Map focus
    (displayCtrl 36351) ctrlMapAnimAdd [0.7, 0.1, [_mapPosX, _mapPosY, 0]];
    ctrlMapAnimCommit (displayCtrl 36351);
}];

// Edit box for grid. Only to point out to the player where it's on the map.
(displayCtrl 3631400) ctrlAddEventHandler ["EditChanged",{
	params ["_control", "_newText"];

    // https://community.bohemia.net/wiki/Talk:parseNumber
    if (!((parseNumber _newText) == 0) && {count _newText == 6}) then {
        ctrlEnable [3631603, true]; // Enable Grid button
        (displayCtrl 3631603) ctrlSetToolTip "Select grid position";
    } else {
        ctrlEnable [3631603, false]; // Disable Grid button
        (displayCtrl 3631603) ctrlSetToolTip "It requires 6 digits";
    };
}];

// Attack button
(displayCtrl 3631600) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];

    // Select target position
    if (((findDisplay 363) getvariable ["PIG_CAS_SelectedKey", ""]) isEqualTo "") exitWith {}; // Exit on non selected key
    if (((findDisplay 363) getVariable ["PIG_CAS_MagazineSelection", ""]) isEqualTo "") exitWith {}; // Exit on non selected magazine 

    _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    _keySupport = (findDisplay 363) getvariable ["PIG_CAS_SelectedKey", "STRAFING RUN"];
    _magazineWeapon = (findDisplay 363) getVariable ["PIG_CAS_MagazineSelection", ""];
    _ammoCount = (findDisplay 363) getVariable ["PIG_CAS_magazineAmmoCount", 0];
    _airStrikePos = (findDisplay 363) getVariable ["PIG_CAS_airStrikePos", [0,0,0]];
    _dir = (findDisplay 363) getVariable ["PIG_CAS_airStrikeDir", 0];
    _caller = (findDisplay 363) getVariable ["PIG_CAS_supportCaller", _caller];

    //_plane setVariable ["PIG_CAS_magazineWeaponSelected", _magazineWeapon];

    if !(_plane getVariable ["PIG_CAS_isAttackButton", false]) exitWith {};

    [_plane, _keySupport, _magazineWeapon, _ammoCount, _airStrikePos, _dir, _caller] call PIG_fnc_planeAttackPlan;

    [] call PIG_CAS_fnc_resetAttackMarkers;
    // Clear variables
    (findDisplay 363) setvariable ["PIG_CAS_SelectedKey", nil];
    (findDisplay 363) setVariable ["PIG_CAS_MagazineSelection", nil];
    (findDisplay 363) setVariable ["PIG_CAS_airStrikePos", nil];
    //_control ctrlEnable false; // Disable this button
}];

// Cancel attack button
(displayCtrl 3631600) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];

    _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    if (_plane isEqualTo objNull) exitWith {};
    if (_plane getVariable ["PIG_CAS_isAttackButton", false]) exitWith {};

    // Cancel attack action
    ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
    [(driver _plane), "Attack cancelled."] remoteExec ["sideChat", PIG_CAS_callers];
    _plane setVariable ["PIG_CAS_isAttacking", false];

    [] call PIG_CAS_fnc_resetAttackMarkers;
    _control ctrlEnable false; // Disable this button
}];

// RTB button
(displayCtrl 3631601) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];
    _control ctrlEnable false; // Disable this button
    _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    private _isRTB = [_plane] call PIG_fnc_planeRTB;
    if (_isRTB) then {
        _groupID = _plane getVariable "PIG_CAS_pilotGroupID";
        ["PIG_CAS_RTB_Notification", [_groupID, _groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers]; // Notification
        [] call PIG_fnc_updateCasMenu; // Update Menu
    };
}];

// Take Off button
(displayCtrl 3631602) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];
    _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    _loiterPos = (findDisplay 363) getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]];
    if (_loiterPos isEqualTo [0,0,0]) exitWith {
        0 spawn {hintSilent parseText "<t size='1.2' shadow='2'>Select loiter position in the map</t>"; sleep 2; hint ""}
    };
    _loiterRadius = _plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius];

    private _tookOff = [_plane, _loiterPos, _loiterRadius] call PIG_fnc_planeTakeOff;
    if (_tookOff) then {
        _plane setVariable ["PIG_CAS_loiterCasPosition", _loiterPos, true];
        _groupID = _plane getVariable "PIG_CAS_pilotGroupID";

        ["PIG_CAS_takingOff_Notification", [_groupID]] remoteExec ["BIS_fnc_showNotification", PIG_CAS_callers]; // Notification
        
        [_plane] call PIG_fnc_planeTracker;
        [_plane] call PIG_fnc_updateCasMenu; // Update Menu
        [] call PIG_CAS_fnc_resetAttackMarkers;
    };
}];

// Mouse button unpressed
(displayCtrl 36351) ctrlAddEventHandler ["MouseButtonUp",{
	params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    _airStrikePos = (findDisplay 363) getVariable ["PIG_CAS_airStrikePos", [0,0,0]];
    if (_airStrikePos isEqualTo [0,0,0]) exitWith {};
    if (_button == 0) then {
        _displayOrControl setVariable ["PIG_CAS_MouseButtonDown", false];
    };
}];

// Loiter Size
(displayCtrl 36351) ctrlAddEventHandler ["MouseZChanged",{
	params ["_displayOrControl", "_scroll"];

    _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    if (_plane isEqualTo objNull) exitWith {};

    if ((displayCtrl 36351) getVariable ["PIG_CAS_keyCtrlDown", false]) then {
        private _size = getMarkerSize "PIG_CAS_marker_loiterPosEllipse";

        private _sizeAjusted = 0;
        if (_scroll > 0) then {
            _sizeAjusted = ((_size # 0) + 100) min PIG_CAS_LoiterMaxRadius; // Limit to PIG_CAS_LoiterMaxRadius
            //if (_sizeAjusted > PIG_CAS_LoiterMaxRadius) then {_sizeAjusted = PIG_CAS_LoiterMaxRadius};
            "PIG_CAS_marker_loiterPosEllipse" setMarkerSizeLocal [_sizeAjusted, _sizeAjusted];
            _plane setVariable ["PIG_CAS_planeLoiterRadius", _sizeAjusted];
        } else {
            _sizeAjusted = ((_size # 0) - 100) max PIG_CAS_LoiterMinRadius; // Limit to PIG_CAS_LoiterMaxRadius
            //if (_sizeAjusted > PIG_CAS_LoiterMaxRadius) then {_sizeAjusted = PIG_CAS_LoiterMaxRadius};
            "PIG_CAS_marker_loiterPosEllipse" setMarkerSizeLocal [_sizeAjusted, _sizeAjusted];
            _plane setVariable ["PIG_CAS_planeLoiterRadius", _sizeAjusted];
        };
        // Update waypoint
        _wpLoiter = _plane getVariable ["PIG_CAS_loiterWaypoint", []];
        if (_wpLoiter isNotEqualTo []) then {
            _wpLoiter setWaypointLoiterRadius _sizeAjusted;
        };
    }
}];

// Key down 
(displayCtrl 36351) ctrlAddEventHandler ["KeyDown",{
	params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];
    
    private _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    private _loiterPos = ((findDisplay 363) getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]]);
    if ((_loiterPos isEqualTo [0,0,0]) && !(_plane getVariable ["PIG_CAS_isOnBase", false])) then {_loiterPos = (_plane getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]])}; 
    
    if ((_plane isEqualTo objNull) || {_loiterPos isEqualTo [0,0,0]}) exitWith {};
    if (_plane getVariable ["PIG_CAS_isBusy", false]) exitWith {};
    if (_ctrl) then {
        // ctrl = lock zoom to use scroll mouse
        (displayCtrl 36351) ctrlMapAnimAdd [0.4, 1, _loiterPos]; // Lock zoom with zoom
        ctrlMapAnimCommit _displayOrControl;
        (displayCtrl 36351) setVariable ["PIG_CAS_keyCtrlDown", true]
    };
    if (_key isEqualTo 28) then {
        // Enter key == double click (for loiter)
        _loiterPos = (_control ctrlMapScreenToWorld [_mouseX, _mouseY]);

    };
}];

// Key up
(displayCtrl 36351) ctrlAddEventHandler ["KeyUp",{
	params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];

    if (_ctrl) then {
        ctrlMapAnimClear (displayCtrl 36351); // Clear zoom anim
        (displayCtrl 36351) setVariable ["PIG_CAS_keyCtrlDown", false]
    };
}];


// Close button
(displayCtrl 3631604) ctrlAddEventHandler ["ButtonClick",{
	params ["_control"];

    closeDialog 2
}];

// On Display/Dialog closed
(findDisplay 363) displayAddEventHandler ["Unload",{
	params ["_display", "_closedChildDisplay", "_exitCode"];

    PIG_CAS_availablePlanes = nil;
    PIG_CAS_menuMarkers = nil;
    PIG_CAS_protectedMarkers = nil;
    PIG_CAS_attackMarkers = nil;
    PIG_CAS_fnc_loiterPosMarker = nil;

    // Delete all created markers for the menu
    deleteMarkerLocal "PIG_CAS_callerMarker";
	deleteMarkerLocal "PIG_CAS_marker_strikePos";
    deleteMarkerLocal "PIG_CAS_seadMovePos";
    deleteMarkerLocal "PIG_CAS_marker_strikeDir";
    deleteMarkerLocal "PIG_CAS_marker_targetPosEllipse";
    deleteMarkerLocal "PIG_CAS_marker_loiterPos";
    deleteMarkerLocal "PIG_CAS_marker_loiterPosEllipse";
    deleteMarkerLocal "PIG_CAS_marker_SelectedPlane";
    deleteMarkerLocal "PIG_CAS_marker_gridPoint";
    deleteMarkerLocal "PIG_CAS_markerAttackDir";
	deleteMarkerLocal "PIG_CAS_markerAttackPos";

    // Clear variables
    _display setVariable ["PIG_CAS_loiterCasPosition", nil];
    _display setVariable ["PIG_CAS_airStrikePos", nil];
    _display setVariable ["PIG_CAS_supportCaller", nil];
    //PIG_jetCas_supports = nil;
    _display setVariable ["PIG_CAS_planeObject", nil];
    _display setVariable ["PIG_CAS_SelectedKey", nil];
    _display setVariable ["PIG_CAS_MagazineSelection", nil];
    _display setVariable ["PIG_CAS_magazineAmmoCount", nil];
    (displayCtrl 36351) setVariable ["PIG_CAS_MouseButtonDown", nil];
    if (!isNil "PIG_CAS_mehIndex_eachFrame") then {
        removeMissionEventHandler ["EachFrame", PIG_CAS_mehIndex_eachFrame];
        deleteMarkerLocal "PIG_CAS_marker_followPlane";
        PIG_CAS_mehIndex_eachFrame = nil;
    };
}];

/* 
    ToDo:
        Check the call airstrike
        Remove take off button - Join with RTB button. Make it a double button. CAS on base = Take Off; CAS in Air = RTB.
            Aircraft can RTB anytime if it's in <<air>>
            Aircraft can only take off if it's <<ready>> and <<onbase>>
        Move to new loiter position with double click
        Seek usage for controls mouseMoving
        Why aircraft is respawning??? answer: handledamage EH
        Attach marker to marker (loiter pos loiter radius)
*/

// Double click to select new loiter position
(displayCtrl 36351) ctrlAddEventHandler ["MouseButtonDblClick",{
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    if (((findDisplay 363) getvariable ["PIG_CAS_SelectedKey", ""]) isNotEqualTo "") exitWith {}; // Exit on selected key
    if (((findDisplay 363) getVariable ["PIG_CAS_MagazineSelection", ""]) isNotEqualTo "") exitWith {}; // Exit on selected magazine 

    // Get mouse position
    getMousePosition params ["_mouseX", "_mouseY"];
    //_control setVariable ["PIG_CAS_MouseButtonDown", true];

    if (_button == 0) then {
        // Double left click
        _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
        if (_plane isEqualTo objNull) exitWith {};
        private _loiterPos = (_control ctrlMapScreenToWorld [_mouseX, _mouseY]);

        if (_plane getVariable ["PIG_CAS_isOnBase", false]) then {
            // Plane on base
            (findDisplay 363) setVariable ["PIG_CAS_loiterCasPosition", _loiterPos];
            [_plane, _loiterPos, PIG_CAS_LoiterMinRadius, PIG_CAS_loiterBaseMarkerColor] call PIG_CAS_fnc_loiterPosMarker; // Create marker
            _mapGrid = mapGridPosition _loiterPos;
            (displayCtrl 3631400) ctrlSetText (_mapGrid);
        } else {
            // Plane in air
            if (_plane getVariable ["PIG_CAS_isBusy", false]) exitWith {};
            ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
            [(driver _plane), "Copy. Moving to the new loiter position"] remoteExec ["sideChat", PIG_CAS_callers];
            _plane setVariable ["PIG_CAS_loiterCasPosition", _loiterPos, true];
            private _loiterRadius = _plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius];
            [_plane, _loiterPos, _loiterRadius, PIG_CAS_loiterActiveMarkerColor] call PIG_CAS_fnc_loiterPosMarker; // Create marker
            [_plane, _loiterPos, _loiterRadius, PIG_CAS_loiterActiveMarkerColor] call PIG_fnc_createLoiterWaypoint;
        }
    };   
}];

// Reset combo boxes with left mouse click
(findDisplay 363) displayAddEventHandler ["MouseButtonDown", { 
	params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    getMousePosition params ["_mouseX", "_mouseY"];
    
    if (_button == 1) then {
        _ctrl = _displayOrControl ctrlAt [_mouseX, _mouseY];
        if ((_ctrl isEqualTo (displayCtrl 3632100)) || (_ctrl isEqualTo (displayCtrl 3632101)) || (_ctrl isEqualTo (displayCtrl 3632102))) then {
           [] call PIG_fnc_updateCasMenu; // Update menu to reset combo boxes
        }
    };
}];

// Reset markers (local to the caller) by clicking on them
(displayCtrl 36351) ctrlAddEventHandler ["MouseButtonDown", { 
	params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    _plane = ((findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull]);
    if (_plane isEqualTo objNull) exitWith {};
    
    if (_button == 1) then {
        // Right click
        private _mapMarker = (displayCtrl 36351) getVariable ["PIG_CAS_mapMarkerSign", ""];
        
        if !((toLowerANSI _mapMarker) in PIG_CAS_menuMarkers) exitWith {}; // Avoid displacing any other map marker

        if (_mapMarker isNotEqualTo "") then {
            // Check for protected markers
            if ((toLowerANSI _mapMarker) in PIG_CAS_attackMarkers) exitWith {
                // Reset all attack markers
                [] call PIG_CAS_fnc_resetAttackMarkers;
                [_plane] call PIG_fnc_updateCasMenu;
                (findDisplay 363) setVariable ["PIG_CAS_airStrikePos", nil];
            };
            if (((toLowerANSI _mapMarker) in PIG_CAS_loiterMarkers) && {_plane getVariable ["PIG_CAS_isOnBase", false]}) then {
                // Remove loiter marker and pos if the airplane is on base
                (findDisplay 363) setVariable ["PIG_CAS_loiterCasPosition", nil];
                [] call PIG_CAS_fnc_resetLoiterMarkers;
            };

            // Don't "remove" protected markers
            if ((toLowerANSI _mapMarker) in PIG_CAS_protectedMarkers) exitWith {};

            _mapMarker setMarkerPosLocal [99999,99999,0];
        };

    };
}];

// Update grid edit box
(displayCtrl 36351) ctrlAddEventHandler ["MouseButtonDown", { 
	params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    
    if (_button == 0) then {
        getMousePosition params ["_mouseX", "_mouseY"];
        //_displayOrControl setVariable ["PIG_CAS_MouseButtonDown", true];

        private _mapPos = (_displayOrControl ctrlMapScreenToWorld [_mouseX, _mouseY]);
        // Right click
        _mapGrid = mapGridPosition _mapPos;
        (displayCtrl 3631400) ctrlSetText (_mapGrid);
    };
}];

// Camera checkbox
private _cbCheck = _caller getVariable ["PIG_CAS_cameraChecked", false];
(displayCtrl 3632800) cbSetChecked _cbCheck;

(displayCtrl 3632800) ctrlAddEventHandler ["CheckedChanged", {
    params ["_control", "_checked"];
    private _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];
    private _caller = (findDisplay 363) getVariable ["PIG_CAS_supportCaller", player];
    
    if (_checked == 1) then {
        if (_plane isEqualTo objNull) exitWith {_control cbSetChecked false}; // Set it to false
        _caller setVariable ["PIG_CAS_cameraChecked", true];
        [_plane, _caller, true] call PIG_fnc_planeCamera;
    } else {
        _caller setVariable ["PIG_CAS_cameraChecked", false];
        [_plane, _caller, false] call PIG_fnc_planeCamera;
    };
    
}];

// Create draws
(displayCtrl 36351) ctrlAddEventHandler ["Draw", { 
	params ["_controlOrDisplay"];

    private _plane = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull];

    // Draw plane attacking
    if (_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {
        _targetLogic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
        if (!isNull _targetLogic) then {
            _controlOrDisplay drawArrow [(getPosASL _plane), (getPosASL _targetLogic), [1,0,0,1]]
        };
        if ((_plane getVariable ["PIG_CAS_attackSupportType", "SEAD"]) == "SEAD") then {
            {
               _controlOrDisplay drawEllipse [_x, 10, 10, 0, [0.9, 0.5, 0, 1], ""];
            }forEach (_plane getVariable ["PIG_CAS_radarTargets", []]);

            {
                _controlOrDisplay drawIcon [
                    "a3\ui_f\data\igui\cfg\weaponcursors\missile_gs.paa", // custom images can also be used: getMissionPath "\myFolder\myIcon.paa"
                    [1,0,0,1],
                    getPosASL _x,
                    32,
                    32,
                    0,
                    "Radar Targeted",
                    1,
                    0.05,
                    "TahomaB",
                    "right"
                ]
            }forEach (_plane getVariable ["PIG_CAS_targetingRadars", []]);

            {
                _controlOrDisplay drawTriangle
                [
                    [
                        // triangle 1 start
                        _x getRelPos [30, 0],
                        _x getRelPos [30, -135],
                        _x getRelPos [30, 135]
                        // triangle 1 end
                    ],
                    [1,0,0,0.9],
                    "#(rgb,1,1,1)color(1,1,1,1)"
                ];
            }forEach (_plane getVariable ["PIG_CAS_seadProjectiles", []]);
        };
    };

    // Draw evasive manuever
    if (_plane getVariable ["PIG_CAS_isEvading", false]) exitWith {
        _retreatPos = _plane getVariable ["PIG_CAS_retreatPos", [0,0,0]];
        if (_retreatPos isNotEqualTo [0,0,0]) then {
            _controlOrDisplay drawArrow [(getPosASL _plane), _retreatPos, [0,0,1,1]]
        };
    };

    // Draw loiter pos / rtb pos
    if (_plane getVariable ["PIG_CAS_isOnBase", false]) then {
        private _loiterPos = (findDisplay 363) getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]];
        if (_loiterPos isNotEqualTo [0,0,0]) exitWith {
            _controlOrDisplay drawArrow [(getPosASL _plane), _loiterPos, [0.70, 0.60, 0.00, 1.00]]
        };
    } else {
        if (_plane getVariable ["PIG_CAS_isRTB", false]) then {
            private _rtbPos = _plane getVariable ["PIG_CAS_originalJetPos", [0,0,0]];
            _controlOrDisplay drawArrow [(getPosASL _plane), (_rtbPos # 0), [0,0,1,1]]
        } else {
            private _loiterPos = _plane getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]];
            if (_loiterPos isNotEqualTo [0,0,0]) exitWith {
                _controlOrDisplay drawArrow [(getPosASL _plane), _loiterPos, [0,0,1,1]]
            };
        }
    };
}];