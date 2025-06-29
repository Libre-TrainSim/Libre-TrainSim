extends Resource
class_name ControllerSettings

enum Devices {
	LUNA,
	OUYA,
	PS3,
	PS4,
	PS5,
	STADIA,
	STEAM,
	SWITCH,
	JOYCON,
	VITA,
	WII,
	WIIU,
	XBOX360,
	XBOXONE,
	XBOXSERIES,
	STEAM_DECK
}

## Controller type to fallback to if automatic
## controller detection fails
@export var joypad_fallback: Devices = Devices.XBOX360

# Controller deadzone for triggering an icon remap when input
# is analogic (movement sticks or triggers)
@export var joypad_deadzone := 0.5 # (float, 0.0, 1.0)

# Allow mouse movement to trigger an icon remap
@export var allow_mouse_remap: bool := true

# Minimum mouse "instantaneous" movement for
# triggering an icon remap
@export var mouse_min_movement := 200 # (int, 0, 10000)

# Custom asset lookup folder for custom icons
@export var custom_asset_dir := "" # (String, DIR)

# Custom generic joystick mapper script
@export var custom_mapper: Script : Script
