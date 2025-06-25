/*
    The payloads/magazines of the registered aicraft are automatic loaded in a function (fn_registerSupport.sqf) into the cas menu everytime you select an aircraft.
    For modded aircraft, If you find any problem in the automatic setup (magazines not in order, wrong magazines for the type of the support you want), you can add manually those magazines here in the order that you want.
    For this, you need some basic knowledge of the type of ammunition you want to put in the aircraft, because each type of support the aircraft and support itself will be handled differently.
    For example: an aircraft must be vectored (forced by a script) to be able to make a rocket or a strafing run on the target position, in the order hand, for dropping a bomb, it doesn't need to aim directly to the target.
    So if you put the magazines that you want in the wrong support order, you won't achieve the main goal of this menu.
    Tip:
        - Place the aircraft in the editor, put a variable name for it, and change it's loadout.
        - Play the scenario, open debug menu, and use commands like "magazinesAllTurrets" to get the magazines class names.
        - Add the varname of the aircraft below.
        - Get those magazines from the command and put them in order in the array bellow. Don't touch the first strings "STRAFING RUN", "AIR-TO-GROUND", etc.
        - Put the class names of the magazines inside the array, follow example below.
    Model:
        [
            exampleVarName2, // aircraft's varname
            [
                ["STRAFING RUN", []], // Default main gun
                ["LASER-GUIDED ROCKETS", []], // Laser guided rockets
                ["LASER-GUIDED BOMBS", []], // Laser guided bombs
                ["AIR-TO-GROUND", []], // AGM (IR missiles/bombs)
                ["GP BOMBS", []], // Dumb bombs (e.g. Mk82)
                ["GP ROCKETS", []], // Non-guided rockets
                ["CLUSTER", []], // Clusters
                ["INFRARED AA", []], // Anti-air (IR)
                ["SEAD", []] // Anti-radiation
            ]
        ]
    Example:
        [
            f18, // FIR Aircraft
            [
                ["STRAFING RUN", ["FIR_M61A2_578rnd_M"]],
                ["LASER-GUIDED ROCKETS", ["FIR_APKWS_M247_P_14rnd_M", "FIR_Scalpel_P_2rnd_M"]],
                ["LASER-GUIDED BOMBS", []],
                ["AIR-TO-GROUND", []],
                ["GP BOMBS", []],
                ["GP ROCKETS", []],
                ["CLUSTER", ["FIR_AGM154A_P_1rnd_M", "FIR_AGM154A_P_1rnd_M"]],
                ["INFRARED AA", ["FIR_AIM9M_P_1rnd_M", "FIR_AIM9M_P_1rnd_M"]],
                ["SEAD", []]
            ]
        ]

*/

PIG_CAS_manualCfg = [
    [
        
    ]
];