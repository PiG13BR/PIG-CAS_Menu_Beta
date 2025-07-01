class PIG_CAS_RscPlanePiP
{
    idd = 37;
    fadein = 0;
    fadeout = 0;
    duration = 1e11; // "Forever"
    onLoad = "uinamespace setVariable ['PIG_CAS_pipDisplay',_this select 0]";
    onUnLoad = "uinamespace setVariable ['PIG_CAS_pipDisplay', nil]";
    movingEnable = false;
    class Controls 
    {
        class BackgroundPiP
        {
            idc = -1;
            style = ST_BACKGROUND;
            font = "RobotoCondensedBold";
            x = 0.762407 * safezoneW + safezoneX;
            w = 0.223046 * safezoneW;
            y = 0.205935 * safezoneH + safezoneY;
            h = 0.280062 * safezoneH;
            colorText[] = {1,1,1,1};
            colorBackground[] = {0.1,0.1,0.1,1};
            text = "";
            lineSpacing = 1;
            sizeEx = 0.01;
            fixedWidth = 1;
            deletable = 0;
            fade = 0;
            access = 0;
            type = CT_STATIC;
            shadow = 1;
            colorShadow[] = {0,0,0,0.5};
            tooltipColorText[] = {1,1,1,1};
            tooltipColorBox[] = {1,1,1,1};
            tooltipColorShade[] = {0,0,0,0.65};
        };
        class planePiP
        {
            idc = -1;
            style = ST_PICTURE;
            font = "RobotoCondensedBold";
            x = 0.768967 * safezoneW + safezoneX;
            w = 0.209925 * safezoneW;
            y = 0.261947 * safezoneH + safezoneY;
            h = 0.210047 * safezoneH;
            colorText[] = {1,1,1,1};
            colorBackground[] = {0,0,0,0};
            text = "#(argb,512,512,1)r2t(rttcas,1.0)";
            lineSpacing = 1;
            sizeEx = 0.02;
            fixedWidth = 1;
            deletable = 0;
            fade = 0;
            access = 0;
            type = CT_STATIC;
            shadow = 1;
            colorShadow[] = {0,0,0,0.5};
            tooltipColorText[] = {1,1,1,1};
            tooltipColorBox[] = {1,1,1,1};
            tooltipColorShade[] = {0,0,0,0.65};
        };
        class textPlanePiP
        {
            idc = 37100;
            font = "PuristaBold";
            x = 0.768967 * safezoneW + safezoneX;
            y = 0.219938 * safezoneH + safezoneY;
            w = 0.209925 * safezoneW;
            h = 0.0280062 * safezoneH;
            colorText[] = {1,1,1,1};
            colorBackground[] = {0.1,0.1,0.1,1};
            text = "Aircraft";
            style = ST_CENTER;
            lineSpacing = 1;
            sizeEx = 0.04;
            fixedWidth = 0;
            deletable = 0;
            fade = 0;
            access = 0;
            type = CT_STATIC;
            shadow = 1;
            colorShadow[] = {0,0,0,0.5};
            tooltipColorText[] = {1,1,1,1};
            tooltipColorBox[] = {1,1,1,1};
            tooltipColorShade[] = {0,0,0,0.65};
        };

    };
};