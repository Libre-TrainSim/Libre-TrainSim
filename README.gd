extends Node
## Hosted on github: ###

## Hobby Project which was startedd christmas 2019.
## Code Licensed unter GNU 3.0 License
## Materials, Objects and Content seen Ingame is Licensed unter CC0 License

## What works:
## Correct curved Rails, The trains are dricing on real circles at curved Rails.
## 		See the Math.gd Script for more information
## Complete Chunkk system.
##		On The World Node you will find a Option "Create Chunks and Save". Whenn you defined a FileName and pressing this Button, the Chunk System will go over all rail nodes. And save all Objects in "Rails",  "Buildings", and "Flora", which are in this chunks or neighboured chunks of the rails.
##		Ingame it will only load all neighboured Chunks and the chunk itself of the current position.
## (Almost) corrct physicly Train Driving: It supports, Acceleration, BrakeAcceleration and Friction. The Displayed Speed is in km/h
## Easy creating of forests and similar things. (In the Multimesh Settings Geometry Override Matierial must be set that the texture is displayed ingame
## Camera Movemente in the Train Cabine for getting the feeling of real driving.
## Sparely 3D Objects
## Not the badest performace thanks to multimeshes which are used in Forests, and Rails..
## Building Rails helps whith making curves, and calculators for parallel rails and shifts are implemented too. But For that maybe will be an assistand programmed which handles it automaticley. (Godot does not update the textfields in the editor. For updating, choose another node in the szene tab and go back to see new calculated values.

## All objects where made whith gimp and blender.
## Most Textures are from OpenGameArt
## Code is completely self written. Thanks to the GoDot Discord Community, which helped me out with one or two problems.




## To be implemented for Version 1.0
## Signals
## Real Train Stations
## Some more Objects And Tracks.
## Main Menu
## Addon Support
## Sound
## Detailed Cockpits
## Helpers for e.g. Walls near the Tracks, electric Rails...
## Rails and Driving whith grades.
## 3D Outer view of the Train
## Content Database hosted in the web and accesible for every one. (For Tracks, Objects, and Trains)

## Further Ideas:
## KI Trains
## Moving Persons at the Platforms.
## Easier Track Building
## Some 3D Effects. (Shadows tested, but they are ripping of the Performance)
## Ground Editor (maybe implementing that plugin from zylan ;) )
## Real Drinving Plans
## Importing Rail Data from Open Street Map
