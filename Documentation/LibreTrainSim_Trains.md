**Attention: This topic is very complex, you need some basic programming skills. Also basic knowledge about the GoDot Engine is required. It is recommended, to get in touch to Libre TrainSim first while building a track.**

You can download an example [here](https://www.server-jean.de/LibreTrainSim/JFR-1.zip).
We won't do a step by step tutorial, because every train works differntly, and has other features.

## General:
A train is handled in a normal single .tscn file (=a single scene). It cointains 3D Models an lights of every wagon, the basic funtionality, and specific scripting. Because of its 'raw' implementation it is possible to add e.g. complete new security systems, and much more. So modding is 'very easy'.

All files can be stored in a single folder. It is very important to download and set up the Editor. -> You can look in [this article](https://github.com/Jean28518/Libre-TrainSim/wiki/Getting-Started,-Preparing-your-World) if you don't know how to do. Under "Trains" you can then create a new folder. In there create a new scene, which save name is equal to the name, how the Train-Name is displayed in LibreTrainSim Menu. For example: `ICE4.tscn`.

If you don't understand something feel free to explore, and modify the example above. Of course it's okay to reuse some files of the exxample for your own train!

LODs are currently not supported.

## Essential Setup:
- The Root-Node of the Train (Train.tscn) should be a Spatial (3D) Scene, and be named `Player`. It should have attached the following script: `res://addons/Libre_Train_Sim_Editor/Data/Scripts/Player.gd`. NEVER CHANGE THIS SCRIPT!
- A Camera Node (Type Camera (3D)) called `Camera`. The Camera should be positioned correctly in the Cabin.
- A Spatial (3D) Node called `Cabin`. In it there should be everything you see from the drivers stand. (Displays, Brake/Acceleration Rolls, etc.). Please make sure that the 3D Stuff is at the "real" position compared to the outer view. Of the wagon node. Usually this position is not at (0,0,0). *Example: The Cabin of the JFR-1 is at (5.3,0,0)*
- One or more "Wagon-Nodes" (3D/Spatial Node). With following script attached: `res://addons/Libre_Train_Sim_Editor/Data/Scripts/Wagon.gd`. In it there should be the 3D Object of the outerview of the wagon. *If a wagon should have movable doors: Two AnimationPlayers should be attached. The first one called `DoorRight` and the second one `DoorLeft`. Every door has to be added as single 3D Object and should be placed at the correct position of the wagon* These wagons are only shown, if you see the train from the outside.
- A Sound Node: (Simple 3D/Spatial Node) called `Sound`. Under it every possible sound (AudioStreamPlayer3D) should be attached. **Because every train has other "sound types" the sounds have to be programmed completely by you.** You could attach this custom script to the sound node. Read the sound section below for more informations
- A FrontLight Node: (Simple 3D/Spatial Node) called `FrontLight`. Should be self explaining. In it there should be attached two spot lights. Here are some default-settings: ##Bildeinfügen##. They should be "turned on" in the scene.
- A CabinLight Node: (Simple 3D/Spatial Node) called `CabinLight`. Works like the the FrontLightNode. Please remind that this is only for the drivers-stand.

**The Problem with the lights** Because of limitations from GoDot Libre TrainSim doesn't support Lights for the passenger rooms. With GoDot 4.0 this will be fixed.

## Train Attributes:
All important settings can be set at the `Player` Node in the Inspector. Here you find very many variables: ##Bild##

- **Acceleration**: Acceleration of the train in m/(s^2). (Applied at 100% Acceleration)
- **Brake Acceleration**: Like Acceleration but for the brakes. Self explaining. Unit: m/(s^2)
- **Friction**: Self explaining. Per second the speed is multiplied by (1-Friction). Example at Friction = 0.005: 100km/h -(after 1 Second)-> 100 km/h * (1-0.005) = 99.5 km/h
- **Length**: Describes the length of the whole train.
- **Speed Limit**: Maximum speed, to it the player can technically accelerate.
- **Control Type**:
    - 0: The 'simple' assignement: You can only control the train with the arrow keys, even you didn't chose 'Easy Mode' before playing.
    - 1: If the player deselected 'Easy Mode' before playing: He will be able to drive via "WASD", so a separated Brake and Acceleration Roll is simulated. Just choose this mode, if your train really has  separate Brake, ans sparate Acceleration.
- **Electric**: The Train is an electric one. In the beginning of the scenario you have to press B to rise the pantograph.
- **Pantograph Time**: describes how long it does take, to rise the pantograph. Unit: seconds
- **Doors**: If checked, the Train will have the ability to open and close doors.
- **Doors Closing Time**: Self explaining.. Unit in seconds.
- **Braking Speed**: Describes the value, how much percent Brakes could be applied in a second. 0.3 is 30%.
- **Brake Release Speed**: Describes the value, how much percent Brakes could be released in a second.
- **Acceleration Speed**: Describes the value, how much percent Acceleration could be applied in a second.
- **Acceleration Release Speed**: Describes the value, how much percent Acceleration could be released in a second.
- **SiFa Enabled**: If the enabled, and player deselected *Easy Mode*, then he has to press `Space` every 30 seconds.
- **Desciption**: Description, which is displayed, when selecting the train in Main-Menu. With `\n` you can make a new line.
- **Author, Release Date**: Self explaining..
- **Screenshot Path**: Path to a nice picture of the train. It will be shown in the Main Menu, if train selected. The picture should be .png and inside your trains folder. Example: `res://Trains/JFR1/JFR1-White.png`
- **Wagons**: In here you define the composition of the train. In there some wagon nodes should be defined. Of course the same wagon can be assigned multiple in this array.
- **Wagon Distance**: The distance between the wagons. Unit: meter
- **Camera Factor**: Describes, how strong the camera in the cabin moves when accelerating or braking.

## Adding cameras
Apart from cabin view, outer view and free camera, each train can define a custom set of additional cameras.

To define a custom camera (eg: passenger view, onboard camera of any kind), simply add your camera to the train scene. Hint: camera is relative to parent so if you want a passenger camera on third wagon, make sure the camera is a child of the third wagon.

To make the camera accessible two more steps are needed:
- add the camera to the node group `PlayerCameras`. Without this, you won't be able to use it
- now attach the `Camera.gd` script to the camera node

The script exports two variables that you can configure on the node:
- **fixed**: if a camera is fixed, its origin cannot change. Otherwise pushing `WASD` buttons will make it move around, still anchored to the parent
- **accel**: if a camera has `accel` enabled, it will slightly move (just like cambin camera) when the train accelerates or breaks.

Cameras can now be activated by using keys from `3` to `8`.

## Technical Background:
The whole train will be loaded in the world while spawing. If it is a NPC, then such nodes as Camera, HUD, and the Cabin are removed.
The Train has two main parts:
1. The 'Brain', or the Heart: The Player Node itself: It handles the player Input, the speed, the route, stations, signals and so on. How already above described you NEVER should change this. It will be updated over time automaticley, and will have the newest features in the next versions, if it is possible. *This part is next to the 'World' Node the essential of LibreTrainSim.*
2. If a train can be seen by a player, the wagons are rendered. They are only 'decoration', and are making the train imaginable ;) They handle such things as the visual, and the (something) audible, or the visuals of the pantograph. Because every train is different, they can be controlled via a *Specific Script*, wich interacts as an interface between the Player Node, and the Wagons. But the wagons also have their own script (which you shouldn't change), and drive in dependence of the Player Node on the rails.

## Tips:
- Start with a very simple train. -> Simple Object, single wagon, very simple driver cabin. Then expand your trainfunctions further on.
- Try to play with some other trains: Look what changes, if you adjust some variables or swap some objects,...
- Try to use as few lights as possible
- To loop a Sound it should be in .ogg format.
- The sound is not good implemented in 0.7. In 0.8 that will gonna be better..
- Feel free to read the code of player.gd or the specific script in the example. They could help a lot
- If you have questions, feel free to ask here: https://libre-trainsim.de/community

## Helpful articles:
- Animation: https://www.youtube.com/watch?v=18Em80Bfjp4
