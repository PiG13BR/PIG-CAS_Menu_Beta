/*
    File: fn_planeFire.sqf
    Author: PiG13BR (https://github.com/PiG13BR)
    Date: 29/05/2025
    Update Date: 06/06/2025

    Description:
        Manages aircraft fire. Main idea took from moduleCas function by BIS

    Parameter(s):
       _plane - aircraft to fire [OBJECT, defaults to objNull]
       _planeDriver - aircraft pilot [OBJECT, defaults to objNull]
       _logic - logic [OBJECT, defaults to objNull]
       _laserTarget - laser target [OBJECT, defaults to objNull]
       _supportType - support type selected in the cas menu [STRING, defaults to STRAFING RUN]
       _weaponType - aircraft weapon to fire [STRING, defaults to ""]
    
    Returns:
        -
*/

params[
    ["_plane", objNull, [objNull]], 
    ["_planeDriver", objNull, [objNull]], 
    ["_logic", objNull, [objNull]],
    ["_laserTarget", objNull, [objNull]], 
    ["_supportType", "STRAFING RUN", [""]],
    ["_weaponType", "", [""]],
    ["_ammoCount", 0, [0]]
];

if (isNull _plane) exitWith {};
if (isNull _logic) exitWith {_plane setVariable ["PIG_CAS_isAttacking", false]};
if (_weaponType isEqualTo "") exitWith {_plane setVariable ["PIG_CAS_isAttacking", false]};

private _planeSide = _plane getVariable ["PIG_CAS_pilotSide", side _planeDriver];

private _laserType = switch _planeSide do {
    case west : {"LaserTargetW"};
    case east : {"LaserTargetE"};
    case independent : {"LaserTargetI"};
    default {""};
};

if ((isNull _laserTarget) && {count (_plane getVariable ["PIG_CAS_targets", []]) < 1} && {count (_plane getVariable ["PIG_CAS_markedTargets", []]) < 1}) then {
    //--- If laser is non existent, create laser target
    _laserTarget = createvehicle [_laserType, (position _logic), [], 0, "none"]; // Create the laser in the logic's position
};

private _duration = 3; // How much time the aircraft will be firing
private _time = time + _duration; // Actual time + duration
waituntil {
    if (count (_plane getVariable ["PIG_CAS_targets", []]) > 0) then {
        // This is for AIR-TO-GROUND/AA
        if (count (_plane getVariable ["PIG_CAS_markedTargets", []]) > 0) then {
            // Prioritize marked targets
            {
                _planeDriver fireAtTarget [_x, _weaponType];
                _plane setVariable ["PIG_missileTarget", _x];
                //if (_forEachIndex == 3) exitWith {}; // Max 4 targets
                sleep 1; 
            }forEach (_plane getVariable ["PIG_CAS_markedTargets", []])
        } else {
            {
                _planeDriver fireAtTarget [_x, _weaponType];
                _plane setVariable ["PIG_missileTarget", _x];
                if (_forEachIndex == 3) exitWith {}; // Max 4 targets
                sleep 1; 
            }forEach (_plane getVariable ["PIG_CAS_targets", []])
        };
    } else {
        if (count (_plane getVariable ["PIG_CAS_markedTargets", []]) > 0) then {
            // Prioritize marked targets
            {
                _planeDriver fireAtTarget [_x, _weaponType];
                _plane setVariable ["PIG_missileTarget", _x];
                //if (_forEachIndex == 3) exitWith {}; // Max 4 targets
                sleep 1; 
            }forEach (_plane getVariable ["PIG_CAS_markedTargets", []])
        } else {
            // Use laser to guide fire
            if (!isNull _laserTarget) then {
                _planeDriver fireAtTarget [_laserTarget, _weaponType]
            } else {
                ["walkie_sideChat"] remoteExec ["playSound", PIG_CAS_callers];
                [(driver _plane), "No targets in the area."] remoteExec ["sideChat", PIG_CAS_callers];
            }
        };
    };

    _plane setvariable ["PIG_CAS_fireProgress",(1 - ((_time - time) / _duration)) max 0 min 1];
    
    sleep 0.1;

    // Conditions to exit loop
    (isnull _plane)
    || (!alive _plane) 
    || (time > _time) //--- Shoot only for specific period
    || (_supportType == "LASER-GUIDED BOMBS" ) // Only one bomb
    || (_supportType == "GP BOMBS") // Only one bomb
    || (_supportType == "AIR-TO-GROUND") // Only fire necessary missiles on amount of targets (to avoid firing multiple times)
    || (_supportType == "LASER-GUIDED ROCKETS") // Only one rocket
    || (_supportType == "INFRARED AA")
    || (_supportType == "CLUSTER") // Only one bomb
    //|| ((count (_plane getVariable ["PIG_CAS_targets", 0]) == 0)) // (Mostly for Air-To-Ground) cancel if not targets found
    || !(_plane getVariable ["PIG_CAS_isAttacking", false])
};

_plane setVariable ["PIG_CAS_isAttacking", false]; // Attack completed or cancelled