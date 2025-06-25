/*
    Edit GUI: CTRL + I
    missionconfigfile >> "PIG_RscJetCasMenu"
*/
class PIG_RscJetCasMenu
{
    idd = 363;
	movingEnable = true;
    controlsBackground[] = {};
	onLoad = "(_this select 0) setVariable ['PIG_CAS_dialogOpen', true]";
	onUnload = "(_this select 0) setVariable ['PIG_CAS_dialogOpen', false];";
    class controls 
    {
	class Background_main: RscFrame
	{
		idc = -1;
		type = CT_STATIC;
		style = ST_BACKGROUND;
		x = 0.11295 * safezoneW + safezoneX;
		y = 0.0659032 * safezoneH + safezoneY;
		w = 0.78066 * safezoneW;
		h = 0.784175 * safezoneH;
			colorBackground[] = {0.1,0.1,0.1,0.85};
	};
class Background_map: RscFrame
{
	idc = -1;
	type = CT_STATIC;
	style = ST_BACKGROUND;

	x = 0.309755 * safezoneW + safezoneX;
	y = 0.0799063 * safezoneH + safezoneY;
	w = 0.577295 * safezoneW;
	h = 0.756169 * safezoneH;
	colorBackground[] = {0.1,0.1,0.1,0.9};
};
class Background_lb: RscFrame
{
	style = 80;

	idc = 1802;
	x = 0.11951 * safezoneW + safezoneX;
	y = 0.0799063 * safezoneH + safezoneY;
	w = 0.177125 * safezoneW;
	h = 0.700156 * safezoneH;
	colorBackground[] = {0.1,0.1,0.1,0.9};
};
class Frame_aircraft_lb: RscFrame
{
	style = 80;

	idc = 1803;
	x = 0.12607 * safezoneW + safezoneX;
	y = 0.0939094 * safezoneH + safezoneY;
	w = 0.164004 * safezoneW;
	h = 0.322072 * safezoneH;
	colorBackground[] = {0.1,0.1,0.1,0.5};
};
class Frame_support_lb: RscFrame
{
	style = 80;

	idc = 1804;
	x = 0.12607 * safezoneW + safezoneX;
	y = 0.429984 * safezoneH + safezoneY;
	w = 0.164004 * safezoneW;
	h = 0.126028 * safezoneH;
	colorBackground[] = {0.1,0.1,0.1,0.5};
};
class Frame_armament_lb: RscFrame
{
	style = 80;

	idc = -1;
	x = 0.12607 * safezoneW + safezoneX;
	y = 0.570016 * safezoneH + safezoneY;
	w = 0.164004 * safezoneW;
	h = 0.196044 * safezoneH;
	colorBackground[] = {0.1,0.1,0.1,0.5};
};
class Frame_map: RscFrame
{
	idc = -1;
	type = CT_STATIC;
	style = ST_FRAME;
	x = 0.322875 * safezoneW + safezoneX;
	y = 0.0939094 * safezoneH + safezoneY;
	w = 0.551054 * safezoneW;
	h = 0.67215 * safezoneH;
	colorBackground[] = {0.1,0.15,0.1,0.9};
};
class Aircraft_combo: RscCombo
{
	idc = 3632100;

	x = 0.135191 * safezoneW + safezoneX;
	y = 0.163925 * safezoneH + safezoneY;
	w = 0.144324 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Support_combo: RscCombo
{
	idc = 3632101;

	x = 0.135191 * safezoneW + safezoneX;
	y = 0.5 * safezoneH + safezoneY;
	w = 0.144324 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Armament_combo: RscCombo
{
	idc = 3632102;

	x = 0.135191 * safezoneW + safezoneX;
	y = 0.640031 * safezoneH + safezoneY;
	w = 0.144324 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Health_bar: RscProgress
{
	idc = 3631900;

	x = 0.152311 * safezoneW + safezoneX;
	y = 0.247944 * safezoneH + safezoneY;
	w = 0.111523 * safezoneW;
	h = 0.0140031 * safezoneH;
	colorFrame[] = {1, 1, 1, 1};
};
class Fuel_bar: RscProgress
{
	idc = 3631901;

	x = 0.152311 * safezoneW + safezoneX;
	y = 0.317959 * safezoneH + safezoneY;
	w = 0.111523 * safezoneW;
	h = 0.0140031 * safezoneH;
	colorFrame[] = {1, 1, 1, 1};
};
class Ammo_bar: RscProgress
{
	idc = 3631902;

	x = 0.152311 * safezoneW + safezoneX;
	y = 0.72405 * safezoneH + safezoneY;
	w = 0.111523 * safezoneW;
	h = 0.0140031 * safezoneH;
	colorFrame[] = {1, 1, 1, 1};
};
class Text_aircraft: RscText
{
	idc = 3631000;
	style = 2;

	text = "Aircraft";
	x = 0.139191 * safezoneW + safezoneX;
	y = 0.121916 * safezoneH + safezoneY;
	w = 0.137764 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Text_support: RscText
{
	idc = 3631001;
	style = 2;

	text = "Support Type";
	x = 0.139191 * safezoneW + safezoneX;
	y = 0.457991 * safezoneH + safezoneY;
	w = 0.137764 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Text_armament: RscText
{
	idc = 3631002;
	style = 2;

	text = "Armament";
	x = 0.139191 * safezoneW + safezoneX;
	y = 0.598022 * safezoneH + safezoneY;
	w = 0.137764 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Text_health: RscText
{
	idc = 3631003;
	style = 2;

	text = "Health";
	x = 0.152311 * safezoneW + safezoneX;
	y = 0.205934 * safezoneH + safezoneY;
	w = 0.111523 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Text_fuel: RscText
{
	idc = 3631003;
	style = 2;

	text = "Fuel";
	x = 0.152311 * safezoneW + safezoneX;
	y = 0.27595 * safezoneH + safezoneY;
	w = 0.111523 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Text_ammo: RscText
{
	idc = 3631004;
	style = 2;

	text = "Ammo";
	x = 0.152311 * safezoneW + safezoneX;
	y = 0.682041 * safezoneH + safezoneY;
	w = 0.111523 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class map : RscMapControl
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_MAP_MAIN;
	idc = 36351;
	style = ST_MULTI + ST_TITLE_BAR;
	colorBackground[] = {0.969,0.957,0.949,1};
	colorOutside[] = {0,0,0,1};
	colorText[] = {0,0,0,1};
	font = "RobotoCondensedLight";
	sizeEx = 0.04; // "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.3)"
	x = 0.335996 * safezoneW + safezoneX;
	y = 0.121916 * safezoneH + safezoneY;
	w = 0.524813 * safezoneW;
	h = 0.616137 * safezoneH;
};
class Button_strike: RscButton
{
	idc = 3631600;

	text = "Call Airstrike";
	x = 0.519681 * safezoneW + safezoneX;
	y = 0.780062 * safezoneH + safezoneY;
	w = 0.157444 * safezoneW;
	h = 0.0420094 * safezoneH;
};
class Button_RTB: RscButton
{
	idc = 3631601;

	text = "RTB";
	x = 0.224473 * safezoneW + safezoneX;
	y = 0.359969 * safezoneH + safezoneY;
	w = 0.0524813 * safezoneW;
	h = 0.0420094 * safezoneH;
};
class Button_takeoff: RscButton
{
	idc = 3631602;

	text = "Take Off";
	x = 0.139191 * safezoneW + safezoneX;
	y = 0.359969 * safezoneH + safezoneY;
	w = 0.0524813 * safezoneW;
	h = 0.0420094 * safezoneH;
};
class Edit_grid: RscEdit
{
	idc = 3631400;

	text = "000000";
	x = 0.322875 * safezoneW + safezoneX;
	y = 0.780062 * safezoneH + safezoneY;
	w = 0.0656017 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Button_grid: RscButton
{
	idc = 3631603;
	text = "Grid";
	style = ST_CENTER;
	x = 0.395037 * safezoneW + safezoneX;
	y = 0.780062 * safezoneH + safezoneY;
	w = 0.0459212 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class Button_close: RscButton
{
	idc = 3631604;

	text = "Close";
	x = 0.165431 * safezoneW + safezoneX;
	y = 0.794066 * safezoneH + safezoneY;
	w = 0.0852822 * safezoneW;
	h = 0.0420094 * safezoneH;
};
class RscCheckbox_2800: RscCheckbox
{
	idc = 3632800;
	x = 0.834569 * safezoneW + safezoneX;
	y = 0.780062 * safezoneH + safezoneY;
	w = 0.0196805 * safezoneW;
	h = 0.0280062 * safezoneH;
};
class RscText_1010: RscText
{
	idc = -1;
	text = "Camera";
	x = 0.782087 * safezoneW + safezoneX;
	y = 0.780062 * safezoneH + safezoneY;
	w = 0.0524813 * safezoneW;
	h = 0.0280062 * safezoneH;
};
    }
};