extends SafetySystem

var is_sifa_enabled = true
var was_sifa_reset = false

# trigger a lamp in the trains cabin
# this is a signal, so different trains can implement it differently
signal sifa_visual_hint(is_turned_on)

onready var player = find_parent("Player")
func _ready():
	_on_settings_changed()
	pass


func _on_settings_changed():
	# TODO: 
	#   check settings, if sifa disabled in difficulty settings, stop.
	#   connect "settings changed" signal, then re-check if sifa is on
	#   in case the player toggles it in the pause-menu options menu
	# is_sifa_enabled = Options.Difficulty.Sifa  # something like that
	
	is_sifa_enabled = not Root.EasyMode
	set_process(is_sifa_enabled)
	set_process_unhandled_key_input(is_sifa_enabled)


# _force_enabled(true) = enabled
# _force_enabled(false) = disabled
func _force_enabled(is_enabled: bool):
	is_sifa_enabled = true
	set_process(true)
	set_process_unhandled_key_input(true)


func _process(delta: float) -> void:
	if player.speed < Math.kmHToSpeed(3):
		$SifaTimer.stop()
	elif $SifaTimer.is_stopped() and stage == 0:
		$SifaTimer.start()


func _unhandled_key_input(event: InputEventKey) -> void:
	if Input.is_action_just_pressed("SiFa"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		$SifaTimer.start()
		$SifaSound.stop()
		emit_signal("sifa_visual_hint", false)
		was_sifa_reset = true
		stage = 0
		release_emergency_brakes()

var stage = 0
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
