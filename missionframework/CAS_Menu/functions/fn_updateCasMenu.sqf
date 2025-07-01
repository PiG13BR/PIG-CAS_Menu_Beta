/*
    File: fn_updateCasMenu.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 30/04/2025
    Update Date: 28/06/2025

    Description:
        Update CAS menu buttons if and while open. Based on specific events.

    Parameter(s):
       _plane - selected aircraft [OBJECT, defaults to selected airplane from menu (PIG_CAS_planeObject)]
    
    Returns:
        -
*/

params[["_plane", (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull], [objNull]]];

if (dialog && ((findDisplay 363) getVariable ["PIG_CAS_dialogOpen", false])) then {
    PIG_CAS_availablePlanes = PIG_CAS_planeList select {(!isNull (_x # 0)) && {alive (_x # 0)} && {(_x # 0) isKindOf "Plane"}};
    //private _availablePlanesObjects = _availablePlanes apply {_x # 0};
    private _planeSelected = (findDisplay 363) getVariable ["PIG_CAS_planeObject", objNull]; // Get last selected aircraft from lb

    //if (_plane isEqualTo objNull) exitWith {};

    // Update aircraft list?
    if (!alive _plane || (isNull _plane)) exitWith { //  || {!(_plane in _availablePlanesObjects)}
        _lbLastSel = lbCurSel 3632100;
        lbClear 3632100;
        // Fill the plane's listbox
        {
            _type = typeOf (_x # 0); // Get jet type
            _groupID = (_x # 1); // Get group ID
            private _name = getText(configFile >> "CfgVehicles" >> _type >> "displayName"); // Get jet's display name
            _name = _name + " " + "(" + _groupID + ")"; // Update with the group ID 
            lbAdd [3632100, _name];
        }forEach PIG_CAS_availablePlanes;

        (displayCtrl 3632100) lbSetCurSel ((_lbLastSel - 1) max 0);
    };
    
    if (_plane isNotEqualTo _planeSelected) exitWith {}; // If it's not selected airplane from menu, don't update the rest of the menu

    ctrlEnable [3631600, false]; // Disable confirm button
    lbClear 3632101;
    lbClear 3632102;
    ctrlSetText [3631600, "Call Airstrike"];
    _plane setVariable ["PIG_CAS_isAttackButton", true, true];

    // Track the plane locally
    [_plane] call PIG_fnc_planeTracker;
    
    /*
        Button conditions explanation:
        - CAS is on the base?
            - Yes. Disable RTB button as default.
            Is there an aircraft on air and is the aircraft ready?
                - Yes. Disable take off button
                - No.
                Is the aircraft ready?
                    - Yes. Enable take off button
            - No. Disable take off button as default.
            Is the aircraft busy?
                - Yes. Disable RTB button
                - No. Enable RTB button
                Is support available and aircraft not RTB?
                    - Yes. Enable targeting.
                    - No.
                    Is support not available and aircraft RTB?
                        - Yes. Disable RTB button.
                        - No. Disable RTB button. It's flying to AO.
    */
    if (_plane getVariable ["PIG_CAS_isOnBase", false]) then {
        //--------- Plane is already in the base
        //ctrlSetText [3631602, "Take off"];
        //(displayCtrl 3631602) setVariable ["PIG_CAS_isTakeOffButton", true];
        ctrlEnable [3631601, false]; // Disable RTB button
        (displayCtrl 3631601) ctrlSetToolTip "This aircraft is in the base";
        if ((missionNamespace getVariable ["PIG_CAS_inAir", false]) && (_plane getVariable ["PIG_CAS_isReady", false])) then {
            // An airplane is already in the air
            ctrlEnable [3631602, false]; // Disable Take off button
            (displayCtrl 3631602) ctrlSetToolTip "There is a aircraft already in the air";
        } else {
            // No planes in the air
            if (_plane getVariable ["PIG_CAS_isReady", false]) then {
                // Aircraft is ready
                ctrlEnable [3631602, true]; // Enable Take off button
                (displayCtrl 3631602) ctrlSetToolTip "Order this aircraft to takeoff";

                // Status
                (displayCtrl 3631013) ctrlSetText "Ready";
                (displayCtrl 3631013) ctrlSetTextColor [0.15,0.75,0.06,1];

            } else {
                // Aircraft is not ready
                ctrlEnable [3631602, false]; // Disable Take off button
                (displayCtrl 3631602) ctrlSetToolTip "This aircraft is not ready";

                // Status
                (displayCtrl 3631013) ctrlSetText "Not Ready";
                (displayCtrl 3631013) ctrlSetTextColor [0.6,0.05,0.02,1];
            }
        };
    } else {
        //--------- Plane is not in the base
        // Take off button > Loiter button
        ctrlEnable [3631602, false];
        //ctrlSetText [3631602, "Loiter"];
        //(displayCtrl 3631602) ctrlSetToolTip "Move to the new loiter position";
        //(displayCtrl 3631602) setVariable ["PIG_CAS_isTakeOffButton", false];

        if (_plane getVariable ["PIG_CAS_isBusy", false]) then {
            // CAS in air, but it's busy
            ctrlEnable [3631601, false]; // Disable RTB button
            (displayCtrl 3631601) ctrlSetToolTip "This aircraft is busy";
            ctrlEnable [3631602, false]; // Disable loiter button
            (displayCtrl 3631602) ctrlSetToolTip "This aircraft is busy";

            // Status
            (displayCtrl 3631013) ctrlSetText "Busy";
            (displayCtrl 3631013) ctrlSetTextColor [0.96,0.05,0.04,1];

            if (_plane getVariable ["PIG_CAS_isAttacking", false]) then {
                // Cas is attacking a position
                //ctrlEnable [3631602, false]; // Disable loiter button
                (displayCtrl 3631602) ctrlSetToolTip "This aircraft is doing an attack run";
                ctrlEnable [3631601, false]; // Disable RTB button
                (displayCtrl 3631601) ctrlSetToolTip "This aircraft is doing an attack run";
                ctrlSetText [3631600, "Cancel Attack"]; // Attack button > Cancel button
                ctrlEnable [3631600, true]; // Enable cancel button
                _plane setVariable ["PIG_CAS_isAttackButton", false, true];

                // Status
                (displayCtrl 3631013) ctrlSetText "Attacking";
                (displayCtrl 3631013) ctrlSetTextColor [0.79,0.35,0.02,1];
            };

            if (_plane getVariable ["PIG_CAS_isRTB", false]) then {
                // CAS in air, but it's RTB
                ctrlEnable [3631601, false]; // Disable RTB button
                (displayCtrl 3631601) ctrlSetToolTip "This aircraft is RTB";

                (displayCtrl 3631013) ctrlSetText "RTB";
                (displayCtrl 3631013) ctrlSetTextColor [0.96,0.05,0.04,1];
            };

            if (_plane getVariable ["PIG_CAS_isTakingOff", false]) then {
                // CAS in air. Going to AO
                ctrlEnable [3631601, false]; // Disable RTB button
                (displayCtrl 3631601) ctrlSetToolTip "This aircraft is going to the AO";

                (displayCtrl 3631013) ctrlSetText "Taking Off";
                (displayCtrl 3631013) ctrlSetTextColor [0.96,0.05,0.04,1];
            };

            if (_plane getVariable ["PIG_CAS_isEvading", false]) then {
                (displayCtrl 3631013) ctrlSetText "Evading";
                (displayCtrl 3631013) ctrlSetTextColor [0.96,0.05,0.04,1];
            };
        } else {
            // CAS is not busy
            ctrlEnable [3631601, true]; // Enable RTB button
            //ctrlEnable [3631602, true]; // Enable Loiter button
            (displayCtrl 3631601) ctrlSetToolTip "Order this aircraft back to the base";
            // CAS in the air, not busy and not RTB
            if !(_plane getVariable "PIG_CAS_isRTB") then {
                // Fill the second list box with the available armaments
                (findDisplay 363) setvariable ["PIG_CAS_SelectedKey", nil]; // Clear key variable
                (findDisplay 363) setVariable ["PIG_CAS_MagazineSelection", nil]; // Clear magazine variable

                private _substract = 0;
                {
                    _array = (PIG_jetCas_supports get _x);
                    // Only fill list box with keys not empty
                    if (count _array == 0) then { _substract = _substract + 1; continue };
                    lbAdd [3632101, _x];
                    lbSetData [3632101, (_forEachIndex - _substract), _x];
                }forEach (keys PIG_jetCas_supports);
                
                3632101 lbSortBy ["TEXT"];

                // Status
                (displayCtrl 3631013) ctrlSetText "Waiting Orders";
                (displayCtrl 3631013) ctrlSetTextColor [0.04,0.2,0.85,1];
            }
        }
    };
};