/*
    File: fn_planeCamera.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 26/05/2025
    Update Date: 17/06/2025

    Description:
        Creates a camera to track down selected aircraft

    Parameter(s):
       _plane - selected aircraft to attach camera [OBJECT, defaults to objNull]
       _caller - player to see aircraft's camera [OBJECT, defaults to player] 
       _cameraOn - creates or destroy the camera [BOOL, defaults to false]
    
    Returns:
        -
*/

params [["_plane", objNull, [objNull]], ["_caller", player, [objNull]], ["_cameraOn", false, [FALSE]]];

if ((isNull _plane) || (!alive _plane)) exitWith {
    private _camera = _caller getVariable ["PIG_CAS_camera", objNull];
    if !(isNull _camera) then {
        _camera cameraEffect ["terminate", "back"];
        camDestroy _camera;
        _caller setVariable ["PIG_CAS_camera", nil];
    };
};
if (isNull _caller || {!alive _caller}) exitWith {};

if (!isPiPEnabled) exitWith { systemChat "PiP is not enabled in video options"; };

if (_cameraOn) then {
    cutRsc ["PIG_CAS_RscPlanePiP","PLAIN", 0, false]; // Create resource
    private _type = typeOf _plane;
    private _name = getText(configFile >> "CfgVehicles" >> _type >> "displayName");
    private _groupID = _plane getVariable ["PIG_CAS_pilotGroupID", groupID(group(driver _plane))];
    _name = _name + " " + "(" + _groupID + ")";
    private _controlText = ((uinamespace getVariable 'PIG_CAS_pipDisplay') displayCtrl 37100);
    _controlText ctrlSetText (_name);
    
    private _camera = _caller getVariable ["PIG_CAS_camera", objNull];
    if (isNull _camera) then {
        _camera = "camera" camCreate (getPosASL _plane); // Create camera
        _caller setVariable ["PIG_CAS_camera", _camera]; // Save camera
    } else {
        _camera setPosASL (getPos _plane);
    };   
    _camera attachTo [_plane, [0, -20, 4]]; // Attach camera to the aircraft
    _camera cameraEffect ["Internal", "Back", "rttcas"];
    if (sunOrMoon < 1) then {"rttcas" setPiPEffect [1]} else {"rttcas" setPiPEffect [0]};
    _camera camCommit 0;
    cameraEffectEnableHUD true;
} else {
    cutRsc ["RemoveRsc", "PLAIN"]; // Remove resource
    //cutText ["","PLAIN"];
    private _camera = _caller getVariable ["PIG_CAS_camera", objNull];
    if (isNull _camera) exitWith {};
    _camera cameraEffect ["terminate", "back"];
    camDestroy _camera;
    _caller setVariable ["PIG_CAS_camera", nil];
};
