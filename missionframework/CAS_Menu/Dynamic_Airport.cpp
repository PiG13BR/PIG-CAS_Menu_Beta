class AirportBase;

// USS Freedom default configuration
class DynamicAirport_01_F : AirportBase
{
    scope = 1;
    displayName = "USS Freedom Carrier";
    DLC = Jets;

    editorCategory = "EdCat_Structures";
    editorSubcategory = "EdSubcat_AircraftCarrier";
    icon = iconObject_1x1;

    // airplanes with "tailHook = true" will be able to land here
    isCarrier = true;

    ilsPosition[] = { -5, 150 };
    ilsDirection[] = { -0.5, 0.08, 3 };
    ilsTaxiIn[] = { 40, -60, 35, -80, 25, -80, 20, -70, -10, 110 };
    ilsTaxiOff[] = { 40, -60, 35, -80, 25, -80, 20, -70, -10, 110 };
};