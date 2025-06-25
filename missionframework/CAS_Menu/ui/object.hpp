import RscObject;

class PIG_rsc_object
{
    idd = -1;
	movingEnable = true;
    controlsBackground[] = {};
	onLoad = "";
	onUnload = "";
    class controls 
    {
        class RscPicture_1200: RscPicture
        {
            idc = 1200;
            //type = CT_OBJECT;
            access = 0;
            direction[] = {0,0,1};
            text = "\A3\Weapons_F\Data\UI\gear_item_radio_ca.paa"; // #(argb,8,8,3)color(1,1,1,1)
            //model = "\a3\Weapons_F\Ammo\mag_radio.p3d";
            scale = 1;
            shadow = 0;
            up[] = {0,1,0};
            x = 0.559042 * safezoneW + safezoneX;
            y = 0.163925 * safezoneH + safezoneY;
            w = 0.190245 * safezoneW;
            h = 0.658147 * safezoneH;
        };
    }
};

class MyWatch
{
	idd = -1;
	class objects
	{
		class Watch /* : RscObject */
		{
			access = 0;
			shadow = 0;
			idc = 101;
			type = 80;
			model = "\a3\Weapons_F\Ammo\mag_radio.p3d";
			//selectionDate1 = "date1";
			//selectionDate2 = "date2";
			//selectionDay = "day";
			x = 0.7;
			xBack = 0.7;
			y = 0.12;
			yBack = 0.12;
			z = 0.22;
			zBack = 0.22;
			inBack = 0;
			enableZoom = 0;
			direction[] = { -1, 0, -1 };
			up[] = { 0, -1, 0 };
			zoomDuration = 1;
			scale = 0.7;
			waitForLoad = 0;
		};
	};
};