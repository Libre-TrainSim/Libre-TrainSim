extends SafetySystem

var is_sifa_enabled: bool = true
var was_sifa_reset: bool = false

# trigger a lamp in the trains cabin
# this is a signal, so different trains can implement it differently
signal sifa_visual_hint(is_turned_on)

onready var player: LTSPlayer = find_parent("Player")


func _ready() -> void:
	_on_settings_changed()


func _on_settings_changed() -> void:
	# TODO:
	#   connect "settings changed" signal, then re-check if sifa is on
	#   in case the player toggles it in the pause-menu options menu

	# If the train is an ai train, the "Player" node can't be found and player is null => disable Sifa
	is_sifa_enabled = (not Root.EasyMode) and jSettings.get_sifa() and player != null
	set_process(is_sifa_enabled)
	set_process_unhandled_input(is_sifa_enabled)


# _force_enabled(true) = enabled
# _force_enabled(false) = disabled
func _force_enabled(is_enabled: bool) -> void:
	is_sifa_enabled = is_enabled
	set_process(is_enabled)
	set_process_unhandled_input(is_enabled)


func _process(_delta: float) -> void:
	if player.speed < Math.kmh_to_speed(3):
		$SifaTimer.stop()
	elif $SifaTimer.is_stopped() and stage == 0:
		$SifaTimer.start()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("SiFa"):
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		$SifaTimer.start()
		$SifaSound.stop()
		emit_signal("sifa_visual_hint", false)
		was_sifa_reset = true
		stage = 0
		release_emergency_brakes()


var stage: int = 0
func _on_SifaTimer_timeout() -> void:
	emit_signal("sifa_visual_hint", true)
	$SifaTimer.stop()
	$WarningTimer.start()
	was_sifa_reset = false

	stage = 1

	yield( $WarningTimer, "timeout" )
	if was_sifa_reset:
		return

	stage = 2

	$SifaSound.play()
	$WarningTimer.start()

	yield( $WarningTimer, "timeout" )
	if was_sifa_reset:
		return

	stage = 3
	enable_emergency_brakes()
