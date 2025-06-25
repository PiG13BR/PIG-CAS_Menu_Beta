/*
    File: fn_createMenuMarkers.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 16/05/2025
    Update Date: 22/06/2025

    Description:
        Manages the creation of the main markers used in the menu

    Parameter(s):
       -
    
    Returns:
        -
*/

PIG_CAS_menuMarkers = [];
PIG_CAS_protectedMarkers = [];
private _resetPos = [99999,99999,0];

createMarkerLocal ["PIG_CAS_marker_SelectedPlane", _resetPos];
"PIG_CAS_marker_SelectedPlane" setMarkerTypeLocal "loc_plane";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_marker_SelectedPlane";
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_SelectedPlane";

// Loiter markers
PIG_CAS_loiterMarkers = [];
/*
    createMarkerLocal ["PIG_CAS_marker_loiterPos", _resetPos]; 
    "PIG_CAS_marker_loiterPos" setMarkerTypeLocal "hd_dot";
    "PIG_CAS_marker_loiterPos" setMarkerSize [1.2,1.2];
    "PIG_CAS_marker_loiterPos" setMarkerTextLocal "Loiter Position";
*/
createMarkerLocal ["PIG_CAS_marker_loiterPos", _resetPos];
"PIG_CAS_marker_loiterPos" setMarkerTypeLocal "EmptyIcon";
"PIG_CAS_marker_loiterPos" setMarkerSizeLocal [2, 2];
"PIG_CAS_marker_loiterPos" setMarkerTextLocal "Loiter Position";
"PIG_CAS_marker_loiterPos" setMarkerColorLocal "colorBLUE";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_marker_loiterPos";
PIG_CAS_loiterMarkers pushBack "PIG_CAS_marker_loiterPos";
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_loiterPos";

createMarkerLocal ["PIG_CAS_marker_loiterPosEllipse", _resetPos];
"PIG_CAS_marker_loiterPosEllipse" setMarkerShapeLocal "ELLIPSE";
"PIG_CAS_marker_loiterPosEllipse" setMarkerBrushLocal "Border";
"PIG_CAS_marker_loiterPosEllipse" setMarkerColorLocal "ColorBLUE";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_marker_loiterPosEllipse";
PIG_CAS_loiterMarkers pushBack "PIG_CAS_marker_loiterPosEllipse";
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_loiterPosEllipse";

// Attack markers
PIG_CAS_attackMarkers = [];
createMarkerLocal ["PIG_CAS_marker_strikePos", _resetPos];
"PIG_CAS_marker_strikePos" setMarkerTypeLocal "hd_objective";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_marker_strikePos";
PIG_CAS_attackMarkers pushBack "PIG_CAS_marker_strikePos";
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_strikePos";

createMarkerLocal ["PIG_CAS_marker_strikeDir", _resetPos];
"PIG_CAS_marker_strikeDir" setMarkerTypeLocal "mil_arrow2";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_marker_strikeDir";
PIG_CAS_attackMarkers pushBack "PIG_CAS_marker_strikeDir";
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_strikeDir";

createMarkerLocal ["PIG_CAS_marker_targetPosEllipse", _resetPos];
"PIG_CAS_marker_targetPosEllipse" setMarkerShapeLocal "ELLIPSE";
"PIG_CAS_marker_targetPosEllipse" setMarkerBrushLocal "Border";
"PIG_CAS_marker_targetPosEllipse" setMarkerSizeLocal [PIG_CAS_AGMSearchRadius, PIG_CAS_AGMSearchRadius];
PIG_CAS_protectedMarkers pushBack "PIG_CAS_marker_targetPosEllipse";
PIG_CAS_attackMarkers pushBack "PIG_CAS_marker_targetPosEllipse";
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_targetPosEllipse";

createMarkerLocal ["PIG_CAS_seadMovePos", _resetPos];
"PIG_CAS_seadMovePos" setMarkerTypeLocal "hd_objective"; 
"PIG_CAS_seadMovePos" setMarkerTextLocal "SEAD";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_seadMovePos";
PIG_CAS_attackMarkers pushBack "PIG_CAS_seadMovePos";
PIG_CAS_menuMarkers pushBack "PIG_CAS_seadMovePos";

// Committed Attack markers
createMarkerLocal ["PIG_CAS_markerAttackPos", _resetPos];
"PIG_CAS_markerAttackPos" setMarkerTypeLocal "mil_destroy";
"PIG_CAS_markerAttackPos" setMarkerTextLocal "Target Position";
//"PIG_CAS_markerAttackPos" setMarkerColorLocal "ColorRED";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_markerAttackPos";
PIG_CAS_menuMarkers pushBack "PIG_CAS_markerAttackPos";
/*
    createMarkerLocal ["PIG_CAS_markerAttackDir", _resetPos];
    "PIG_CAS_markerAttackDir" setMarkerTypeLocal "mil_arrow";
    "PIG_CAS_markerAttackDir" setMarkerTextLocal "Attack Vector";
    PIG_CAS_protectedMarkers pushBack "PIG_CAS_markerAttackDir";
*/

// Grid marker
createMarkerLocal ["PIG_CAS_marker_gridPoint", _resetPos]; // Can be "deleted" with right click
"PIG_CAS_marker_gridPoint" setMarkerTypeLocal "hd_dot";
"PIG_CAS_marker_gridPoint" setMarkerSizeLocal [1.2, 1.2];
PIG_CAS_menuMarkers pushBack "PIG_CAS_marker_gridPoint";

/*
    createMarker ["PIG_CAS_markerEllipse", _resetPos];
    "PIG_CAS_markerEllipse" setMarkerShape "ELLIPSE";
    "PIG_CAS_markerEllipse" setMarkerBrush "Border";
    "PIG_CAS_markerEllipse" setMarkerSize [PIG_CAS_AGMSearchRadius, PIG_CAS_AGMSearchRadius];
*/

// Caller/player marker
createMarkerLocal ["PIG_CAS_callerMarker", _resetPos];
"PIG_CAS_callerMarker" setMarkerTypeLocal "b_inf";
PIG_CAS_protectedMarkers pushBack "PIG_CAS_callerMarker";
PIG_CAS_menuMarkers pushBack "PIG_CAS_callerMarker";

PIG_CAS_protectedMarkers = PIG_CAS_protectedMarkers apply {toLowerANSI _x};
PIG_CAS_attackMarkers = PIG_CAS_attackMarkers apply {toLowerANSI _x};
PIG_CAS_loiterMarkers = PIG_CAS_loiterMarkers apply {toLowerANSI _x};
PIG_CAS_menuMarkers = PIG_CAS_menuMarkers apply {toLowerANSI _x};
//publicVariable "PIG_CAS_protectedMarkers";