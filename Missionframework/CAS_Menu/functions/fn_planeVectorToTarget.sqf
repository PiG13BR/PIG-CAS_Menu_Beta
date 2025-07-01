/*
    File: fn_planeVectorToTarget.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 23/05/2025
    Update Date: 02/06/2025

    Description:
        The main idea and scripting commands was took from moduleCAS function by BIS (a3\modules_f_curator\CAS\functions\fn_moduleCAS.sqf)
        This function handles the guidance of the aircraft to the target (dive) through vectors
        To make the start "pitching" of the aircraft smoother, this function runs in a scheduler environment

    Parameter(s):
       _plane - plane to vector to target [OBJECT, defaults to objNull]
    
    Returns:
        -
*/

params[["_plane", objNull, [objNull]]];

if (!canSuspend) exitWith {_this spawn PIG_fnc_planeVectorToTarget};
if (isNull _plane) exitWith {};

private _logic = _plane getVariable ["PIG_CAS_moveableLogic", objNull];
if (isNull _logic) exitWith {};
private _posLogic = getPosASL _logic;
private _approachDist = (_plane distance2d _posLogic);
private _approachAlt = (getPosASL _plane # 2);
private _pitchValue = (-90 + atan ((_plane distance _posLogic) / ((getPosATL _plane) # 2))); // Get pitch value from plane position to the target
//private _positivePitch = _pitchValue*(-1); // Convert to a positive value to use in the loop
private _vectorUp = vectorUp _plane;
// Smooth pitch the aircraft to target position
for "_i" from ((_plane call BIS_fnc_getPitchBank) # 0) to (abs _pitchValue) do {
    if !(_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {terminate _thisScript};
    sleep 0.05; // Fast
    [_plane, -_i, 0] call bis_fnc_SetPitchBank; // Pitch the aircraft (notice that the value is negative: -_i)
    _vel = velocityModelSpace _plane; 
    _plane setVelocityModelSpace _vel;
    _vectorUp = vectorUp _plane; // Update vectorUp
};
private _planePosASL = (getPosASL _plane); // Get plane's posASL
private _vectorDir = _planePosASL vectorFromTo _posLogic; // Get the vector direction from plane position to the target position
//private _approachSpeed = 400 / 3.6;
private _velocity = (velocity _plane); // Get plane's velocity // _vectorDir vectorMultiply (_approachSpeed) Multiply the vector direction using the speed
private _duration = ([0,0] distance [_approachDist, _approachAlt]) / (speed _plane/3.6); // this is: time (s) = distance (m) / speed (m/s)

_time = time;
// Now maintain the pitch of the aircraft towards the target
_eachFrameEH = addMissionEventHandler ["Draw3D", {
    _thisArgs params ['_plane', '_planePosASL', '_posLogic', '_velocity','_vectorDir', '_vectorUp', '_time', '_duration'];
    if !(_plane getVariable ["PIG_CAS_isAttacking", false]) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]};
    private _moveableLogic = _plane getVariable ["PIG_CAS_moveableLogic", objNull];
    if (isNull _moveableLogic) exitWith {removeMissionEventHandler [_thisEvent, _thisEventHandler]};
    
    private _posLogic = getPosASL _moveableLogic; // Get logic position
    private _planePos = getPosASL _plane; // Get plane's posASL
    private _vectorDir = _planePos vectorFromTo _posLogic; // Get the vector direction from plane position to the target position
    private _pitchValue = (-90 + atan ((_plane distance _posLogic) / ((getPosATL _plane) # 2)));
    [_plane, _pitchValue, 0] call bis_fnc_SetPitchBank;
    private _vectorUp = vectorUp _plane;
    

    // private _iconPos = getPosASLVisual _moveableLogic;
    // drawIcon3D ["a3\ui_f_curator\data\cfgcurator\laser_ca.paa", [0.9,0,0,1], (ASLToAGL _iconPos), 1, 1, 45, "Target", 1, 0.05, "TahomaB"];
    // drawLine3D [(ASLToAGL _planePos), (ASLtoAGL _iconPos), [1,0,0,1]];
    
    // Basically what is in moduleCas function by BIS
    private _offSet = _plane getVariable ["PIG_CAS_targetOffSet", 0];
    private _fireProgress = _plane getvariable ["PIG_CAS_fireProgress", 0]; // this will increase "toPosASL" slight when the aircraft fires...
    _plane setVelocityTransformation [
        _planePosASL, [_posLogic select 0, _posLogic select 1, ((_posLogic select 2) + _offSet + (_fireProgress * 12))],
        _velocity, _velocity,
        _vectorDir,_vectorDir,
        _vectorUp, _vectorUp,
        (time - _time) / _duration
    ];
}, [_plane, _planePosASL, _posLogic, _velocity, _vectorDir, _vectorUp, _time, _duration]];