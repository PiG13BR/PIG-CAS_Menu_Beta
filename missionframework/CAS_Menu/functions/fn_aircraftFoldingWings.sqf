/*
    Author: Bravo Zero One development
    - John_Spartan

    Description:
    - This function is designed to prevent take off with folded wings on the Jets DLC aircraft that have such useraction/function enabled.

    Exucution:
    - Call the function via int EH on each aircrfat config
        class Eventhandlers: Eventhandlers
        {
            engine = "_this call bis_fnc_aircraftFoldingWings";
            gear = "_this call bis_fnc_aircraftFoldingWings";
        };

    Requirments:
    - Compatible aircrfat must have a config definition for all subsytems that will be invoked by this function

        example of cfgVehicles subclass definitions;
        class AircraftAutomatedSystems
        {
            wingStateControl = 1;                                                                                //enable automated wing state control to prevent player to take off with folded wings
            wingFoldAnimations[] = {"wing_fold_l","wing_fold_r","wing_fold_cover_l", "wing_fold_cover_r"};        //foldable wing animation list
            wingStateFolded = 1;                                                                                //animation state when folded
            wingStateUnFolded = 0;                                                                                //animation state when un-folded
            wingAutoUnFoldSpeed = 40;                                                                            //speed treshold when triger this feature, and unfold wings for player

        };

    Parameter(s):
        _this select 0: mode (Scalar)
        0: plane/object


    Returns: nothing
    Result: Aircrfat should not be able to take off/ fly with wings folded

*/

/*
    Edited by: PiG13BR
    Date: 17/06/2025

    Description:
        Simplification of the function to use on AI airplanes
    
    Parameter(s):

*/

params [["_plane", objNull, [objNull]], ["_state", false, [FALSE]]];

if (isNull _plane || {!local _plane || {!alive _plane}}) exitWith {};

private _configPath = configFile >> "CfgVehicles" >> typeOf _plane  >> "AircraftAutomatedSystems";
private _wingStateControl = (_configPath >> "wingStateControl") call BIS_fnc_getCfgDataBool;    if (!_wingStateControl) exitWith {};
private _wingFoldAnimationsList = (_configPath >> "wingFoldAnimations" ) call BIS_fnc_getCfgData;
private _wingStateFolded = (_configPath >> "wingStateFolded") call BIS_fnc_getCfgData;
private _wingStateUnFolded = (_configPath >> "wingStateUnFolded") call BIS_fnc_getCfgData;
private _wingAutoUnFoldSpeed = (_configPath >> "wingAutoUnFoldSpeed") call BIS_fnc_getCfgData;

if (_state) then {
    {
        if (_plane animationPhase _x < _wingStateFolded) then
        {
            _plane animate [_x,_wingStateFolded];
        };
    }foreach _wingFoldAnimationsList;

} else {
    // Unfold wings
    {
        if (_plane animationPhase _x >= _wingStateFolded) then
        {

            _plane animate [_x,_wingStateUnFolded];
        };
    }foreach _wingFoldAnimationsList;
};