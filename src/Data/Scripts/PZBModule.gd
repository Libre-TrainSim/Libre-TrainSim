extends SafetySystem

# This is a simplified version of PZB.
# we only check speed at certain points, and not continuously
# There might also be some Edge Cases that are not 100% correct.

const PZB_SPEED_MAX = 165.0
const PZB_SPEED_1000_START = PZB_SPEED_MAX
const PZB_SPEED_1000_END = 85.0
const PZB_SPEED_500_START = 65.0
const PZB_SPEED_500_END = 45.0

const PZB_SPEED_1000_RESTRICTIVE_THRESHOLD = 10.0
const PZB_SPEED_1000_RESTRICTIVE = 45.0

const PZB_SPEED_500_RESTRICTIVE_THRESHOLD_START = 30.0
const PZB_SPEED_500_RESTRICTIVE_THRESHOLD_END = 10.0
const PZB_SPEED_500_RESTRICTIVE = 25.0

# passing the module so that the connected node can get all information it wants
# most likely only needs mode and magnet, but maybe wants speed_limit as well!
signal pzb_changed(pzb_module)

enum PZBType {
	HEAVY_FREIGHT = 55, # not yet coded
	LIGHT_FREIGHT = 70, # not yet coded
	PASSENGER = 85
}
var pzb_type: int = PZBType.PASSENGER setget set_type

enum PZBMode {
	DISABLED =    0b0000_0000, # 0
	IDLE =        0b0000_0001, # 1
	MONITORING =  0b0000_0010, # 2
	RESTRICTIVE = 0b0000_0100, # 4
	EMERGENCY =   0b0000_1000, # 8
	MASK_MODE =   0b0000_1111,
	_HIDDEN =     0b0001_0000, # 16
	_500Hz =      0b0010_0000, # 32
	_1000Hz =     0b0100_0000, # 64
	_2000Hz =     0b1000_0000, # 128
	MASK_MAGNET = 0b1111_0000
}
var pzb_mode: int = PZBMode.IDLE setget set_mode
var pzb_speed_limit: float setget set_speed_limit  # no speed limit

var pzb_command_pressed: bool = false

onready var player: LTSPlayer = find_parent("Player")


func _ready() -> void:
	$"153mMonitor".set_player(player)
	$"250mMonitor".set_player(player)
	$"700mMonitor".set_player(player)
	$"1250mMonitor".set_player(player)

	_on_settings_changed()

	pzb_speed_limit = Math.kmh_to_speed(PZB_SPEED_MAX)


func _on_settings_changed() -> void:
	# TODO:
	#   connect "settings changed" signal, then re-check if pzb is on
	#   in case the player toggles it in the pause-menu options menu

	var is_pzb_enabled: bool = (not Root.EasyMode) and jSettings.get_pzb()

	if is_pzb_enabled:
		pzb_reset()
	else:
		pzb_mode = PZBMode.DISABLED
	set_process(is_pzb_enabled)
	set_process_unhandled_key_input(is_pzb_enabled)
	emit_signal("pzb_changed", self)


# _force_enabled(true) = enabled
# _force_enabled(false) = disabled
func _force_enabled(is_enabled: bool) -> void:
	set_process(is_enabled)
	set_process_unhandled_key_input(is_enabled)

	if not is_enabled:
		pzb_mode = PZBMode.DISABLED
	else:
		pzb_reset()


func set_mode(new_val: int) -> void:
	pzb_mode = new_val
	emit_signal("pzb_changed", self)


func set_type(new_val: int) -> void:
	pzb_type = new_val
	emit_signal("pzb_changed", self)


func set_speed_limit(new_val: float) -> void:
	pzb_speed_limit = new_val
	emit_signal("pzb_changed", self)


func pzb_reset() -> void:
	pzb_mode = PZBMode.IDLE
	release_emergency_brakes()
	emit_signal("pzb_changed", self)


func _calc_pzb_speed_limit():
	if pzb_mode & (PZBMode.IDLE | PZBMode.DISABLED):
		pzb_speed_limit = Math.kmh_to_speed(PZB_SPEED_MAX)

	elif pzb_mode & PZBMode.RESTRICTIVE:
		if pzb_mode & (PZBMode._1000Hz | PZBMode._HIDDEN):
			pzb_speed_limit = Math.kmh_to_speed(PZB_SPEED_1000_RESTRICTIVE)
		elif pzb_mode & PZBMode._500Hz:
			var alpha = 1.0 - ($"153mMonitor".distance_left() / $"153mMonitor"._distance)
			pzb_speed_limit = Math.kmh_to_speed(lerp(PZB_SPEED_1000_RESTRICTIVE, PZB_SPEED_500_RESTRICTIVE, alpha))

	elif pzb_mode & PZBMode.MONITORING:
		if pzb_mode & (PZBMode._1000Hz | PZBMode._HIDDEN):
			var alpha = 1.0 - ($SpeedTimer.time_left / $SpeedTimer.wait_time)
			pzb_speed_limit = Math.kmh_to_speed(lerp(PZB_SPEED_1000_START, PZB_SPEED_1000_END, alpha))
		elif pzb_mode & PZBMode._500Hz:
			var alpha = 1.0 - ($"153mMonitor".distance_left() / $"153mMonitor"._distance)
			pzb_speed_limit = Math.kmh_to_speed(lerp(PZB_SPEED_500_START, PZB_SPEED_500_END, alpha))


func _check_restrictive_mode():
	if player.speed <= 0:
		restrictive_mode()
		return

	var threshold = PZB_SPEED_1000_RESTRICTIVE_THRESHOLD
	if pzb_mode & PZBMode._500Hz:
		var alpha = 1.0 - ($"153mMonitor".distance_left() / $"153mMonitor"._distance)
		threshold = lerp(PZB_SPEED_500_RESTRICTIVE_THRESHOLD_START, \
						 PZB_SPEED_500_RESTRICTIVE_THRESHOLD_END, \
						 alpha)

	if player.speed < Math.kmh_to_speed(threshold):
		if $RestrictiveTimer.is_stopped() and (pzb_mode & PZBMode.MONITORING):
			$RestrictiveTimer.start()
	elif not $RestrictiveTimer.is_stopped():
		$RestrictiveTimer.stop()


func _process(_delta: float) -> void:
	_calc_pzb_speed_limit()

	if player.speed > pzb_speed_limit and not (pzb_mode & PZBMode.EMERGENCY):
		send_message(tr("PZB_OVER_SPEED_LIMIT"))
		emergency_brake()

	_check_restrictive_mode()


func _unhandled_key_input(_event: InputEventKey) -> void:
	if Input.is_action_just_pressed("pzb_ack"):
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")

	# you can hold down the ack button before the signal and still trigger it :)
	if Input.is_action_just_released("pzb_ack"):
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		if not $AckTimer.is_stopped():
			$AckTimer.stop()
			mode_1000hz()

	if Input.is_action_just_pressed("pzb_free"):
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		if not (pzb_mode & (PZBMode._1000Hz | PZBMode._500Hz | PZBMode.EMERGENCY)) \
		or (pzb_mode & PZBMode.EMERGENCY and player.speed == 0):
			release_emergency_brakes()
			if pzb_mode & PZBMode._HIDDEN:
				pzb_mode = PZBMode.IDLE | PZBMode._HIDDEN
			else:
				pzb_mode = PZBMode.IDLE
			emit_signal("pzb_changed", self)

	if Input.is_action_just_pressed("pzb_command"):
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		pzb_command_pressed = true
	if Input.is_action_just_released("pzb_command"):
		pzb_command_pressed = false


func mode_1000hz() -> void:
	var was_already_monitoring: bool = pzb_mode & (PZBMode.MONITORING | PZBMode.RESTRICTIVE | PZBMode._HIDDEN)

	# 1000 Hz magnet ALWAYS resets to Monitoring 1000Hz!!
	pzb_mode = PZBMode.MONITORING | PZBMode._1000Hz
	emit_signal("pzb_changed", self)

	$"700mMonitor".start()
	$"1250mMonitor".start() # if monitoring was on before, 1250m RESETS!!

	# if monitoring was on before (ie 2x 1000Hz magnet within 1250m)
	# then we SKIP the 23 seconds timer!
	if not was_already_monitoring:
		# the false is important, it prevents the timer from running when the game is paused
		$SpeedTimer.start()
	else:
		set_speed_limit(Math.kmh_to_speed(PZB_SPEED_1000_END))


func mode_500hz() -> void:
	if pzb_mode == PZBMode.IDLE:
		send_message(tr("PZB_ILLEGAL_FREE"))
		emergency_brake()
	elif not (pzb_mode & PZBMode.EMERGENCY):
		if player.speed > Math.kmh_to_speed(PZB_SPEED_500_START):
			send_message(tr("PZB_FAST_500HZ"))
			emergency_brake()

		pzb_mode &= ~PZBMode.MASK_MAGNET  # disable any magnet info
		pzb_mode |= PZBMode._500Hz  # enable 500Hz
		$"153mMonitor".start()
		$"250mMonitor".start()

		emit_signal("pzb_changed", self)


# "start" mode, when train is first put into forward
func _on_reverser_changed(state: int) -> void:
	if pzb_mode == PZBMode.DISABLED:
		return

	if state == ReverserState.FORWARD and pzb_mode == PZBMode.IDLE:
		pzb_mode = PZBMode.RESTRICTIVE | PZBMode._HIDDEN
		restrictive_mode()


func restrictive_mode() -> void:
	if pzb_mode & PZBMode.EMERGENCY:
		return

	pzb_mode &= ~PZBMode.MASK_MODE   # disable current mode
	pzb_mode |= PZBMode.RESTRICTIVE  # enable restrictive

	# start mode is equal to RESTRICTIVE_HIDDEN (ie. 1000Hz mode after 700m)
	# this means it deactivates after 550 meters
	if (pzb_mode & PZBMode.MASK_MAGNET) == 0:  # if no magnet is active
		$"1250mMonitor".start()
		$"1250mMonitor"._start_dist = player.distance_on_route - 700

	emit_signal("pzb_changed", self)


func _on_passed_signal(signal_instance: Spatial) -> void:
	if pzb_mode == PZBMode.DISABLED:
		return

	if signal_instance.type == "PZBMagnet" and signal_instance.is_active:
		match signal_instance.hz:
			1000:
				$AckTimer.start()
			500:
				mode_500hz()
			2000:
				if pzb_command_pressed:
					return
				send_message(tr("PZB_PASSED_2000HZ"))
				pzb_mode |= PZBMode._2000Hz
				emergency_brake()


func emergency_brake() -> void:
	pzb_mode &= ~PZBMode.MASK_MODE
	pzb_mode |= PZBMode.EMERGENCY
	enable_emergency_brakes()
	emit_signal("pzb_changed", self)


func _on_700m_reached() -> void:
	if not pzb_mode & PZBMode._1000Hz:
		return
	pzb_mode &= ~PZBMode.MASK_MAGNET  # disable 1000Hz
	pzb_mode |= PZBMode._HIDDEN   # enable hidden
	emit_signal("pzb_changed", self)


# PZB Monitoring (1000 Hz hidden) disables after 1250 meters
# not if 500 Hz mode had enabled at any point
func _on_1250m_reached() -> void:
	if pzb_mode & PZBMode._HIDDEN:
		pzb_reset()


# 500Hz Mode stops after 250 meters
# but if it is restrictive, then it stays restrictive!
func _on_250m_reached() -> void:
	if pzb_mode == PZBMode.EMERGENCY:
		return

	# 500Hz restrictive = 25km/h, but 500Hz just disabled, so reset to 45km/h
	if pzb_mode & PZBMode.RESTRICTIVE:
		pzb_mode = PZBMode.RESTRICTIVE | PZBMode._HIDDEN
	else:
		pzb_mode = PZBMode.IDLE

	emit_signal("pzb_changed", self)


func send_message(msg: String) -> void:
	player.send_message(msg)
