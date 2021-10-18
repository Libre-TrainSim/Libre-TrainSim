extends Control


const MAX_LOAD_TIME_STEP = 1.0


export(Array, String) var descriptions = []


var loader: ResourceInteractiveLoader
var resources := []
var scenes := []
var instance_thread := Thread.new()
var thread_done := false
var thread_done_mutex := Mutex.new()
var is_instancing := false


func _ready() -> void:
	assert(descriptions.size() > 0)
	hide()
	set_process(false)


func load_main_menu():
	loader = ResourceLoader.load_interactive("res://addons/Libre_Train_Sim_Editor/Data/Modules/main_menu.tscn")
	get_tree().current_scene.queue_free()
	get_tree().current_scene = self
	set_process(true)
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	jEssentials.remove_all_pending_delayed_calls()
	$ProgressBar/Bar.max_value = loader.get_stage_count()
	$ProgressBar/Bar.value = 0
	$ProgressBar/Description.lines_skipped = 0
	$Screenshot.texture = load("res://screenshot.png") as Texture
	show()


func load_world(world: String, scenario: String, train: String, bg_img: Texture) -> void:
	loader = ResourceLoader.load_interactive(world)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = self
	set_process(true)
	$ProgressBar/Bar.max_value = loader.get_stage_count() - 1
	$ProgressBar/Bar.value = 0
	$ProgressBar/Description.text = descriptions[0]
	$Screenshot.texture = bg_img
	show()


func _process(_delta: float) -> void:
	if is_instancing:
		thread_done_mutex.lock()
		if thread_done:
			instance_thread.wait_to_finish()
			_add_to_tree()
			set_process(false)
			_clear()
			hide()
		thread_done_mutex.unlock()
		return

	var t = OS.get_ticks_msec()
	# use "time_max" to control for how long we block this thread
	while OS.get_ticks_msec() < t + MAX_LOAD_TIME_STEP:
		var err = loader.poll()
		if err == ERR_FILE_EOF: # Finished loading.
			update_progress_bar()
			resources.push_back(loader.get_resource())
			loader = null
			if instance_thread.start(self, "_instanciate_scenes") != OK:
				Logger.warn("Can't create instanciation thread. Loading in main thread", self)
				_instanciate_scenes()
				_add_to_tree()
				set_process(false)
				_clear()
				hide()
				return
			is_instancing = true
			return
		elif err == OK:
			update_progress_bar()
		else: # error during loading
			Logger.err("An error occured during loading! (%s)" % err, self);
			loader = null
			OS.shell_open(ProjectSettings.globalize_path("user://logs/"))
			get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/main_menu.tscn")
			break


func _instanciate_scenes(_args = null) -> void:
	for resource in resources:
		if resource is PackedScene:
			scenes.push_back(resource.instance())
	thread_done_mutex.lock()
	thread_done = true
	thread_done_mutex.unlock()


func _add_to_tree() -> void:
	for i in range(1, scenes.size()):
		scenes[0].add_child(scenes[i])
	get_tree().root.add_child(scenes[0])
	get_tree().current_scene = scenes[0]


func _clear() -> void:
	for scene in scenes:
		# We would leak memory. Ensure the scenes are in the tree
		assert(scene.get_parent() != null)
	scenes.clear()
	resources.clear()
	thread_done = false
	is_instancing = false


func update_progress_bar() -> void:
	$ProgressBar/Bar.value = loader.get_stage()
	$ProgressBar/Description.text = descriptions[\
			int(round(loader.get_stage() * (descriptions.size() - 1) \
					/ float(loader.get_stage_count() - 1)))]
