/*
    Original file from BIS: fn_carrier01CatapultLockTo
    Author: Jiri Wainar

    Modified File: fn_lockPlaneToCatapult
    Author: PiG13BR
    
    Description:
    (Jiri Wainar) Moves player aircraft through interpolation to given catapult and once there locks it there.
    (PiG13BR) Script adaptaded for IA

    Parameter(s):
        _plane - IA jet [OBJECT, defaults to objNull]
        _part - carrier part containing the catapult [OBJECT, defaults to objNull]
        _memPoint - name of catapult memory point [STRING, defaults to ""]
        _dirOffSet - direction offset of the catapult relative to carrier part direction [NUMBER, defaults to 0]

    Returns:
        Nothing.

    Example:
        [cas1, "Land_Carrier_01_hull_04_1_F", "pos_catapult_02", 2.2] call PIG_CAS_fnc_lockPlaneToCatapult;
*/

private _interpolation_move_speed = 5; //in meters/second
private _interpolation_turn_speed = 15; //in degrees/secon
private _interpolation_step_length = 0.001; //smoothness of the interpolation

params
[
    ["_plane", objNull],
    ["_part", objNull],
    ["_memPoint", ""],
    ["_dirOffset", 0]
];

if (isNull _plane) exitWith {};
//terminate if plane is attached to something
if (!isNull attachedTo _plane) exitWith {};

private _posStart = getPosWorld _plane;
private _height = _posStart select 2;
private _posCatapult = _part modelToWorld (_part selectionPosition _memPoint); _posCatapult set [2, _height];

private _vectorUp = vectorUp _plane;

private _posDelta = [_posCatapult,_posStart] call BIS_fnc_vectorDiff;
private _distance = (_posStart distance2D _posCatapult) max 0.1;

private _dirStart = (getDir _plane) % 360;
private _dirCatapult = (getDir _part - _dirOffset - 180) % 360;
private _dirDelta = (_dirCatapult - _dirStart) % 360;

if (_dirDelta < -180) then
{
    _dirDelta = _dirDelta + 360;
}
else
{
    if (_dirDelta > 180) then {_dirDelta = _dirDelta - 360;};
};

/*
["[ ] _dirStart: %1",_dirStart] call bis_fnc_logFormat;
["[ ] _dirCatapult: %1",_dirCatapult] call bis_fnc_logFormat;
["[ ] _dirDelta: %1",_dirDelta] call bis_fnc_logFormat;

["[ ] _posCatapult: %1",_posCatapult] call bis_fnc_logFormat;
["[ ] _posStart: %1",_posStart] call bis_fnc_logFormat;
["[ ] _posCatapult: %1",_posCatapult] call bis_fnc_logFormat;

["[ ] _distance: %1",_distance] call bis_fnc_logFormat;
*/

//private _velocity = [_posDelta,_interpolation_move_speed/_distance] call BIS_fnc_vectorMultiply;

private _timeMax = 0.75 * (getNumber(missionConfigFile >> "CfgCarrier" >> "LaunchSettings" >> "duration") max 6);
private _minSpeedMove = _distance / _timeMax;
private _minSpeedTurn = abs(_dirDelta / _timeMax);

//["[ ] MOVE - default speed: %1 | min: %2",_interpolation_move_speed,_minSpeedMove] call bis_fnc_logFormat;
//["[ ] TURN - default speed: %1 | min: %2",_interpolation_turn_speed,_minSpeedTurn] call bis_fnc_logFormat;

private _timeMove = _distance / (_interpolation_move_speed max _minSpeedMove);
private _timeTurn = abs(_dirDelta / (_interpolation_turn_speed max _minSpeedTurn));
private _timeStart = time;
private _timeDelta = 0;

//private ["_posOffset","_posPlane","_dirOffset","_dirPlane"];
while {!(_plane getVariable ["PIG_CAS_catapulted", false]) && {isNull attachedTo _plane}} do
{
    _timeDelta = time - _timeStart;
    _plane setVectorUp _vectorUp;

    //moving: lock airplane
    if (_timeDelta >= _timeMove) then
    {
        _plane setPosWorld _posCatapult;
        _plane setVelocity [0,0,0];
    }
    //moving: interpolate airplane
    else
    {
        _posOffset = [_posDelta,_timeDelta/_timeMove] call BIS_fnc_vectorMultiply;
        _posPlane = _posStart vectorAdd _posOffset; _posPlane set [2, _height];
        _plane setPosWorld _posPlane;
    };

    //turning: lock airplane
    if (_timeDelta >= _timeTurn) then
    {
        _plane setDir _dirCatapult;
    }
    //turning: interpolate airplane
    else
    {
        _dirOffset = _dirDelta * _timeDelta/_timeTurn;
        _dirPlane = _dirStart + _dirOffset;
        _plane setDir _dirPlane;
    };

    sleep _interpolation_step_length;
};