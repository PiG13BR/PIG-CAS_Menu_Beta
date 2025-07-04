# CAS MENU (BETA)
- **This is not a final product, it's still in development.**
- Tested only in SP environment. It still needs to make multiple changes and fixes to work on Dedicated Servers.
## Description (W.I.P)
- We all know that AI can't provided adequate air support. This script is aim to add a functional and an immersive CAS to the players.
- It was inspired in the support modes of the [World in Conflict](https://en.wikipedia.org/wiki/World_in_Conflict), a classic RTS game.
- The first sketch of the menu was based directly on the **moduleCas function from BIS**. It still uses some code lines from that function, particullary involing the [setVelocityTransformation](https://community.bistudio.com/wiki/setVelocityTransformation) to force aircrafts dive, aiming to the target position.
- To make the AI obedient, the pilots from the aircrafts will always be in ```CARELESS``` behaviour, so, they **will not engage in an air-to-air combat against others aircrats nor it will attack ground targets by himself**, the CAS MENU is scripted to only provide CAS for the players on the ground once **requested**.
- Tested with vanilla and modded aircrafts (most populars ones).

![imagem_2025-07-01_120320862](https://github.com/user-attachments/assets/3d2f38f1-7273-4ff0-9096-e757fd2914c8)
## Features (W.I.P)
- The aircrafts will takeoff and land on its registered airport.
  - **USS Freedom:** aircraft can be launched from it using its catapults and it will be recover after landing.
- Once the airplane took off from the designed airport, it will loiter a provided position in the map, and wait for orders.
- Available supports (pylon dependent and automatic configuration):
  - Strafing run (main-gun)
  - Laser-guided rockets
  - Laser-guided bombs
  - Air-to-ground (against IR targets on ground within radius)
  - General pupose bombs and rockets
  - Cluster
  - Infrared air-to-air (against helicopters)
  - SEAD (anti-radiation missiles)
- The aircraft will be handled differently in some support types.
- The aircraft's available supports can be manually added in the [PIG_CAS_supportManualConfig.sqf](https://github.com/PiG13BR/PIG-CAS_Menu_Beta/blob/main/Missionframework/CAS_Menu/PIG_CAS_supportManualConfig.sqf) file. Useful for modded aircrafts if the automatic configuration doesn't work right.
- Some menu basic configuration can be changed in the [PIG_CAS_configuration.sqf](https://github.com/PiG13BR/PIG-CAS_Menu_Beta/blob/main/Missionframework/CAS_Menu/PIG_CAS_configuration.sqf) file.
- Follow the aircraft by a PiP camera.
## Installation
- Copy all files from Missionframework folder into your mission folder.
## In-game Steps
### Preparation 
- The aircraft must be placed in the airport where is going to takeoff and land. It must be a registered airport in the map's config. Some airports IDs and related locations you can find [here](https://community.bistudio.com/wiki/Arma:_Airport_IDs).
- Additionally, you can find the airport's ID using the [allAirports](https://community.bistudio.com/wiki/allAirports) command. Sadly, we don't have any command that return the airport position in the map, but generally, the "0" ID is the main airport of the island/map.
- Use [landAt](https://community.bistudio.com/wiki/landAt) command (Syntax 1) on a flying airplane to confirm the airport's ID. Futhermore, you will need to to check jet's behaviour once its lands (land/taxi/takeoff directions).
- The AI in an airplane in an airport will try to get to the taxiway in the most dumb way as possible, so the airplane must be placed a few meters away from the main taxi route and aimed to that, without any obstacles. The AI is unpredictable, so you will need to check this multiple times. Once you get the right place in the airport to place the aircrafts, you don't need to worry about it anymore.
  - Aircrafts in airbases will get a slight push before taxiing it. If you see this is as a problem, just remove or comment ```//``` the command ```setVelocityModelSpace``` in [fn_planeTakeOff.sqf](https://github.com/PiG13BR/PIG-CAS_Menu_Beta/blob/main/Missionframework/CAS_Menu/functions/fn_planeTakeOff.sqf).
- If the map doesn't have a designated airport, even though you can cleary see an airport, you can still create your own [dynamic airport](https://community.bistudio.com/wiki/Arma_3:_Dynamic_Airport_Configuration), so the AI can taxi, takeoff and land.
- **CARRIER**
  - The vanilla carrier (USS Freedom) is already configurated to work with the CAS Menu.
  - To verify if an aircraft can use the carrier to takeoff and land: aim to the aircraft that you want to check, and execute this code in the menu debug: ```getNumber(configFile >> "cfgVehicles" >> typeOf CursorObject >> TailHook)```
  - If returns 1, then the aircraft can use the carrier (Vanilla airplanes: only the F/A-181)
### Registering the aircraft in the designated airport
- Once you have the airport and its ID, register the aircraft by putting the code below in the unit's init field:
  - In this form, it will take as default the main airport of the island (ID: 0). ``` [this] call PIG_fnc_registerAircraft``` 
  - If you have a different airport ID, place as second argument in the array:  ``` [this, 1] call PIG_fnc_registerAircraft```
  - If you have a dynamic airport, get the class: ```[this, "myDynamicAirport"] call PIG_fnc_registerAircraft```
  - If you're going to use carrier USS Freedom: ```[this, "DynamicAirport_01_F"] call PIG_fnc_registerAircraft```
### Register support services
- The aircraft needs to rearm, refuel and repair once lands in the airbase, to be able to do that, you must also register base services. It can be any object, and it must be near the aircraft spawn point.
  - Register an object with all services: ```[this] call PIG_fnc_registerService;```
  - ```[this, "REPAIR" or "REFUEL" or "REARM" or ["REPAIR", "REARM"] + others combinations] call PIG_fnc_registerService;```
### Register caller
- Of course, we need to register who is going to have access to the the cas menu.
  - Place this in the unit's init box: ```[this] call PIG_fnc_registerCaller```
- In theory, multiple players can have access to it, but this is still a working in progress.
## Using the CAS MENU (W.I.P)
- Open the CAS MENU by the default action interface or by adding a key to the custom control "User Action 12".
### Takeoff
1. Select an airplane.
2. **DOUBLE LMB** on the map to select a loiter position. You can also change the loiter's size by pressign **CTRL** and using **SCROLL-WHEEL**
- All aircrafts before taking off must have a position to loiter.
- Once the aircraft is waiting for orders, you can change its loiter position and its loiter size anytime, by pressing the same buttons.
- You can turn on the camera option in the right corner of the menu.

    ![takingoff](https://github.com/user-attachments/assets/537c3339-4935-455b-89bd-de106e4733f0)
### Attacking
1. Select an airplane.
2. Choose the support type.
3. Select available ammunition.
4. Select the attack position on the menu map.
      - You can also choose the attack direction in supports type like **"STRAFING-RUN"** and **"CLUSTER"**, by **PRESSING LMB + MOVING THE MOUSE**, an arrow can be seen where the aircraft will be coming from.
5. Confirm the attack by pressing "Call Airstrike".
      - The aircraft will follow some pre-defined waypoints and drop its payload into the target position.

    ![attacking](https://github.com/user-attachments/assets/c2f4d68c-f115-4156-a2c7-f939a5c25edb)
### Marking targets
- This can be achieve while the aircraft is on the attack path. The airplane must been selected.
- In some support types, like **"LASER-GUIDED BOMBS"**, you can mark ground enemy assets near the target position by laser targetting and pressing **TARGET BUTTON** (Default: T).
- You can also mark targets in **"AIR-TO-GROUND"** support type. In this case you can prioritize targets with IR signature (e.g. engine on) in the area of attack.

    ![markingtargets](https://github.com/user-attachments/assets/c3897c8b-3020-4435-b2f7-42ad00b7ecbb)
### RTB
- Select any available airplane in air and click the **RTB** button in the menu.
- The airplane will return to the airbase, land, taxi off and once stops, it'll be teleported to the starting position.

    ![RTB](https://github.com/user-attachments/assets/5edf6f5c-5fd8-4925-9626-fa9c26f09d3d)
