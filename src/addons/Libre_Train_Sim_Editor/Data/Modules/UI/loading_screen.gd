extends Control


const MAX_LOAD_TIME_STEP = 32.0


export(Array, String) var descriptions = []


var loader: ResourceInteractiveLoader


func _ready() -> void:
	hide()
	set_process(false)


func load_world(world: String, scenario: String, train: String, bg_img: Texture) -> void:
	loader = ResourceLoader.load_interactive(world)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = self
	set_process(true)
	$ProgressBar/Bar.max_value = loader.get_stage_count()
	$ProgressBar/Bar.value = 0
	$ProgressBar/Description.lines_skipped = 0
	$Screenshot.texture = bg_img
	show()


func _process(_delta: float) -> void:
	var t = OS.get_ticks_msec()
	# use "time_max" to control for how long we block this thread
	while OS.get_ticks_msec() < t + MAX_LOAD_TIME_STEP:
		var err = loader.poll()
		if err == ERR_FILE_EOF: # Finished loading.
			set_process(false)
			update_progress_bar()
			yield(get_tree(), "idle_frame")
			var scene = loader.get_resource().instance()
			loader = null
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
			hide()
			return
		elif err == OK:
			update_progress_bar()
		else: # error during loading
			printerr("An error occured during loading!");
			print(err)
			loader = null
			OS.shell_open(ProjectSettings.globalize_path("user://logs/"))
			get_tree().quit(1)
			break


func update_progress_bar() -> void:
	$ProgressBar/Bar.value = loader.get_stage()
	$ProgressBar/Description.lines_skipped = \
			int(round(loader.get_stage() / float(loader.get_stage_count())))
