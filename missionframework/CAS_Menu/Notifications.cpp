class DefaultModel
{
    title = "";				// Title displayed as text on black background. Filled by arguments.
    iconPicture = "";		// Small icon displayed in left part. Colored by "color", filled by arguments.
    iconText = "";			// Short text displayed over the icon. Colored by "color", filled by arguments.
    description = "";		// Brief description displayed as structured text. Colored by "color", filled by arguments.
    color[] = {1,1,1,1};	// Icon and text color
    duration = 5;			// How many seconds will the notification be displayed
    priority = 0;			// Priority; higher number = more important; tasks in queue are selected by priority
    difficulty[] = {};		// Required difficulty settings. All listed difficulties has to be enabled
    sound = "";				// Sound to be played upon notification is created. (cfgSounds)
    soundClose = "";	    // Sound to be played upon notification is collapsed. (cfgSounds)
    soundRadio = "";        // Radio message to be played upon notification is created. HQ entity of player side is used. (cfgRadio)
    colorIconPicture[] = {
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_R',0])",
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_G',1])",
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_B',1])",
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_A',0.8])"
    };
    colorIconText[] = {
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_R',0])",
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_G',1])",
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_B',1])",
        "(profilenamespace getvariable ['IGUI_TEXT_RGB_A',0.8])"
    };
};

class PIG_CAS_takingOff_Notification
{
    title = "%1 is taking off";
    iconPicture = "a3\ui_f_jets\data\gui\cfg\hints\aircrafttakeoffcarrier_ca.paa";
    description = "%1 will provide air support as soon it reachs the loiter position";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_RTB_Notification
{
    title = "%1 is RTB";
    iconPicture = "a3\ui_f_jets\data\gui\cfg\hints\aircraftlandcarrier_ca.paa";
    description = "%1 is going back to the base";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_Available_Notification
{
    title = "%1 is available to provide support";
    iconPicture = "a3\ui_f\data\gui\cfg\communicationmenu\cas_ca.paa";
    description = "%1 is available to provide support";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_LowFuel_Notification
{
    title = "%1 is bingo on fuel";
    iconPicture = "a3\armor_f_decade\mbt_02\data\ui\lowfuel_ca.paa";
    description = "%1 is RTB to refuel";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_Landed_Notification
{
    title = "%1 landed and is on the base";
    iconPicture = "a3\modules_f\data\iconhq_ca.paa";
    description = "%1 landed successfully, and it will be ready shortly";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_Ready_Notification
{
    title = "%1 is ready";
    iconPicture = "a3\missions_f_exp\data\img\lobby\ui_campaign_lobby_icon_player_ready_ca.paa";
    description = "%1 is waiting for orders";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_Attacked_Notification
{
    title = "%1 is getting attacked";
    iconPicture = "a3\ui_f\data\gui\cfg\hints\target_ca.paa";
    description = "The enemy is targetting %1";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_Damaged_Notification
{
    title = "%1 is damaged";
    iconPicture = "a3\ui_f_jets\data\gui\cfg\hints\aircraftdamage_ca.paa";
    description = "%1 took some damage and is RTB";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_OutOfFuel_Notification
{
    title = "%1 is out fuel";
    iconPicture = "a3\ui_f\data\igui\cfg\actions\eject_ca.paa";
    description = "%1 ran out fuel";
    color[] = {1,1,1,1};
    duration = 5;
    sound = "walkieon";
    soundClose = "walkieoff";
};
class PIG_CAS_Down_Notification
{
    title = "%1 is down";
    iconPicture = "a3\ui_f\data\igui\cfg\revive\overlayiconsgroup\f75_ca.paa";
    description = "%1 is down";
    color[] = {1,1,1,1};
    duration = 5;
};
