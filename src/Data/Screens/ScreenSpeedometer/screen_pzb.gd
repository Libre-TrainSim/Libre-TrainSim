extends GridContainer

var pzb_type
var blink_timer
var blink_active = true
var blink_restrictive = false

func _ready():
	var pzb_module = find_parent("Player").get_node("SafetySystems/PZBModule")
	pzb_module.connect("pzb_changed", self, "_on_pzb_changed")

	blink_timer = Timer.new()
	blink_timer.autostart = false
	blink_timer.one_shot = false
	blink_timer.wait_time = 0.5
	blink_timer.connect("timeout", self, "blink")
	self.add_child(blink_timer)

	deactivate_pzb_type()
	deactivate($Befehl40)
	deactivate($"500Hz")
	deactivate($"1000Hz")

	_on_pzb_changed(pzb_module)  # initialize



func blink():
	if blink_restrictive:
		if blink_active:
			activate_pzb_type(70)
		else:
			activate_pzb_type(85)
	else:
		if blink_active:
			deactivate_pzb_type()
		else:
			activate_pzb_type(pzb_type)
	blink_active = !blink_active


func _on_pzb_changed(module) -> void:
	pzb_type = module.pzb_type

	if module.pzb_mode == module.PZBMode.DISABLED:
		for node in get_children():
			if "modulate" in node:
				deactivate(node)
		blink_timer.stop()
		return

	elif module.pzb_mode & module.PZBMode.IDLE:
		blink_timer.stop()
		activate_pzb_type(pzb_type)

	elif module.pzb_mode & module.PZBMode.MONITORING:
		blink_active = true
		blink_restrictive = false
		blink_timer.start()

	elif module.pzb_mode & module.PZBMode.RESTRICTIVE:
		blink_active = true
		blink_restrictive = true
		blink_timer.start()

	elif module.pzb_mode & module.PZBMode.EMERGENCY:
		blink_active = false
		blink_restrictive = false
		deactivate_pzb_type()
		blink_timer.stop()

	if module.pzb_mode & module.PZBMode._1000Hz:
		activate($"1000Hz")
		deactivate($Befehl40)
		deactivate($"500Hz")
	elif module.pzb_mode & module.PZBMode._HIDDEN:
		deactivate($"1000Hz")
		deactivate($Befehl40)
		deactivate($"500Hz")
	elif module.pzb_mode & module.PZBMode._500Hz:
		deactivate($"1000Hz")
		deactivate($Befehl40)
		activate($"500Hz")
	else:
		deactivate($"1000Hz")
		deactivate($Befehl40)
		deactivate($"500Hz")


func activate_pzb_type(type):
	match type:
		55:
			activate($U)
			deactivate($M)
			deactivate($O)
		70:
			deactivate($U)
			activate($M)
			deactivate($O)
		85:
			deactivate($U)
			deactivate($M)
			activate($O)


func deactivate_pzb_type():
	deactivate($U)
	deactivate($M)
	deactivate($O)


func activate(node):
	node.modulate = Color(1,1,1,1)


func deactivate(node):
	node.modulate = Color(0.1, 0.1, 0.1, 1)
