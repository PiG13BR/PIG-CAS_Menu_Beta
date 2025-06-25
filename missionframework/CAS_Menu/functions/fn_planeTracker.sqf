/*
    File: fn_planeTracker.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 01/05/2025
    Update Date: 18/06/2025

    Description:
        Show and track the aircraft (menu map). It also manages aircraft's associate markers.

    Parameter(s):
       _plane - aircraft to track [OBJECT]
    
    Returns:
        -
*/

params["_plane"];

if (dialog && !((findDisplay 363) getVariable ["PIG_CAS_dialogOpen", false])) exitWith {};

// Create marker for jet on ground
"PIG_CAS_marker_SelectedPlane" setMarkerPosLocal (getPos _plane);
"PIG_CAS_marker_SelectedPlane" setMarkerDirLocal (getDir _plane);
private _groupID = _plane getVariable ["PIG_CAS_pilotGroupID", groupID(group(driver _plane))];
private _planeCfg = configfile >> "cfgvehicles" >> typeOf _plane;
"PIG_CAS_marker_SelectedPlane" setMarkerTextLocal (format["%1 - %2",(getText (_planeCfg >> "displayName")), _groupID]);

// Add MEH if CAS is not on base
if !(_plane getVariable ["PIG_CAS_isOnBase", false]) then {
	if !(_plane getVariable ["PIG_CAS_isAttacking", false]) then {
		//"PIG_CAS_markerAttackDir" setMarkerPosLocal [99999,99999,0];
		"PIG_CAS_markerAttackPos" setMarkerPosLocal [99999,99999,0];
		// Loiter marker if not attacking
		private _loiterPos = _plane getVariable ["PIG_CAS_loiterCasPosition", [0,0,0]];
		if (_loiterPos isNotEqualTo [0,0,0]) then {
			"PIG_CAS_marker_loiterPos" setMarkerPosLocal _loiterPos;
			"PIG_CAS_marker_loiterPos" setMarkerColorLocal PIG_CAS_loiterActiveMarkerColor;
			private _loiterRadius = _plane getVariable ["PIG_CAS_planeLoiterRadius", PIG_CAS_LoiterMinRadius];
			"PIG_CAS_marker_loiterPosEllipse" setMarkerSizeLocal [_loiterRadius, _loiterRadius];
			"PIG_CAS_marker_loiterPosEllipse" setMarkerPosLocal _loiterPos;
			"PIG_CAS_marker_loiterPosEllipse" setMarkerColorLocal PIG_CAS_loiterActiveMarkerColor;
		};
	} else {
		"PIG_CAS_marker_loiterPos" setMarkerPos [99999,99999,0];
    	"PIG_CAS_marker_loiterPosEllipse" setMarkerPos [99999,99999,0];
		// Attacking markers
		private _attackDir = _plane getVariable ["PIG_CAS_attackDir", 0];
		private _logic = _plane getVariable ["PIG_CAS_targetLogic", objNull];
		//private _aproachPos = _plane getVariable ["PIG_CAS_approachPos", [0,0,0]];
		private _posLogic = getPosASL _logic;

		if (isNull _logic) exitWith {};

		if ((_plane getVariable ["PIG_CAS_attackSupportType", "STRAFING RUN"]) isEqualTo "SEAD") then {
			"PIG_CAS_seadMovePos" setMarkerPosLocal _posLogic;
		} else {
			"PIG_CAS_markerAttackPos" setMarkerPosLocal _posLogic;
			//"PIG_CAS_markerAttackDir" setMarkerPosLocal _aproachPos;
			//"PIG_CAS_markerAttackDir" setMarkerDirLocal _attackDir;
		}
	};
	// Change plane's marker color
	if (_plane getVariable ["PIG_CAS_isBusy", false]) then {
		"PIG_CAS_marker_SelectedPlane" setMarkerColorLocal PIG_CAS_busyCasMarkerColor;
		// Reset loiter markers
		if !(_plane getVariable ["PIG_CAS_isTakingOff", false]) then {
			[] call PIG_CAS_fnc_resetLoiterMarkers;
		}
	} else {
		"PIG_CAS_marker_SelectedPlane" setMarkerColorLocal PIG_CAS_activeCasMarkerColor;
	};
	if (isNil "PIG_CAS_mehIndex_eachFrame") then {
		PIG_CAS_mehIndex_eachFrame = addMissionEventHandler ["EachFrame", {
			private _plane = (_thisArgs # 0);
			if (isNull _plane || {!alive _plane }|| {!((findDisplay 363) getVariable ["PIG_CAS_dialogOpen", false])}) exitWith {
				removeMissionEventHandler ["EachFrame", _thisEventHandler];
				PIG_CAS_mehIndex_eachFrame = nil;
				[] call PIG_CAS_fnc_resetAttackMarkers;
				[] call PIG_CAS_fnc_resetLoiterMarkers;
			};
			"PIG_CAS_marker_SelectedPlane" setMarkerPosLocal (getPos _plane);
			"PIG_CAS_marker_SelectedPlane" setMarkerDirLocal (getDir _plane);
			[_plane] call PIG_fnc_updateHealthFuel;

		}, [_plane]];
	} else {
		// Remove last MEH and create a new one
		removeMissionEventHandler ["EachFrame", PIG_CAS_mehIndex_eachFrame];
		PIG_CAS_mehIndex_eachFrame = nil;
		PIG_CAS_mehIndex_eachFrame = addMissionEventHandler ["EachFrame", {
			private _plane = (_thisArgs # 0);
			if (isNull _plane || {!alive _plane }|| {!((findDisplay 363) getVariable ["PIG_CAS_dialogOpen", false])}) exitWith {
				removeMissionEventHandler ["EachFrame", _thisEventHandler];
				PIG_CAS_mehIndex_eachFrame = nil;
				[] call PIG_CAS_fnc_resetAttackMarkers;
				[] call PIG_CAS_fnc_resetLoiterMarkers;
			};

			"PIG_CAS_marker_SelectedPlane" setMarkerPosLocal (getPos _plane);
			"PIG_CAS_marker_SelectedPlane" setMarkerDirLocal (getDir _plane);
			[_plane] call PIG_fnc_updateHealthFuel;
		}, [_plane]];
	};
} else {
	[] call PIG_CAS_fnc_resetAttackMarkers;
	[] call PIG_CAS_fnc_resetLoiterMarkers;
	"PIG_CAS_markerAttackPos" setMarkerPosLocal [99999,99999,0];
	/*
	"PIG_CAS_marker_loiterPos" setMarkerPos [99999,99999,0];
    "PIG_CAS_marker_loiterPosEllipse" setMarkerPos [99999,99999,0];
	"PIG_CAS_markerAttackDir" setMarkerPosLocal [99999,99999,0];
	"PIG_CAS_seadMovePos" setMarkerPosLocal [99999,99999,0];
	*/
	"PIG_CAS_marker_SelectedPlane" setMarkerColorLocal PIG_CAS_onBaseCasMarkerColor;
	if !(isNil "PIG_CAS_mehIndex_eachFrame") then {
		removeMissionEventHandler ["EachFrame", PIG_CAS_mehIndex_eachFrame];
		PIG_CAS_mehIndex_eachFrame = nil;
	};
};