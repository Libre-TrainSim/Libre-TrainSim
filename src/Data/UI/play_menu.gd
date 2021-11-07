extends PanelContainer


var currentTrack: String = ""
var currentTrain: String = ""
var currentScenario: String = ""
var screenshot_texture: Texture
var world_config: WorldConfig # config of selected world

func show() -> void:
	update_track_list()
	.show()


func update_track_list() -> void:
	$Play/Selection/Tracks/Tracks.clear()
	for track in ContentLoader.repo.worlds:
		$Play/Selection/Tracks/Tracks.add_item(track.get_file().get_basename())

func update_train_list() -> void:
	$Play/Selection/Trains/Trains.clear()
	for train in ContentLoader.repo.trains:
		$Play/Selection/Trains/Trains.add_item(train.get_file().get_basename())


func _on_Back_pressed() -> void:
	hide()


func _on_Play_pressed() -> void:
	if currentScenario.empty() or currentTrack.empty() or currentTrain.empty():
		return
	var index: int = $Play/Selection/Tracks/Tracks.get_selected_items()[0]
	Root.currentTrack = ContentLoader.repo.worlds[index]
	Root.currentScenario = currentScenario
	Root.currentTrain = currentTrain
	Root.EasyMode = $Play/Info/Info/EasyMode.pressed
	hide()

	LoadingScreen.load_world(Root.currentTrack, currentScenario, currentTrain, screenshot_texture)


func _on_Tracks_item_selected(index: int) -> void:
	currentTrack = ContentLoader.repo.worlds[index]
	Root.checkAndLoadTranslationsForTrack(currentTrack.get_file().get_basename())
	currentScenario = ""
	var save_path: String = ContentLoader.repo.worlds[index].get_basename() + "_config.tres"
	world_config = load(save_path) as WorldConfig

	if world_config.scenarios.empty():
		Logger.err("No scenarios found.", save_path)
		$Play/Info/Description.text = tr("MENU_NO_SCENARIO_FOUND")
		$Play/Selection/Scenarios.hide()
		return
	$Play/Info/Description.text = tr(world_config.track_description)
	$Play/Info/Info/Author.text = " "+ tr("MENU_AUTHOR") + ": " + world_config.author + " "
	$Play/Info/Info/ReleaseDate.text = " "+ tr("MENU_RELEASE") + ": " + String(world_config.release_date["month"]) + " " + String(world_config.release_date["year"]) + " "
	var track_dir: String = currentTrack.get_base_dir()
	Logger.vlog(track_dir)
	$Play/Info/Screenshot.texture = _make_image(track_dir.plus_file("screenshot.png"))

	$Play/Selection/Scenarios.show()
	$Play/Selection/Scenarios/Scenarios.clear()
	$Play/Selection/Trains.hide()
	$Play/Info/Info/EasyMode.hide()

	for scenario in world_config.scenarios:
		# FIXME: remove mobile version hack and replace with resource based loading
		if Root.mobile_version and (scenario == "The Basics" or scenario == "Advanced Train Driving"):
			continue
		if not Root.mobile_version and scenario == "The Basics - Mobile Version":
			continue
		$Play/Selection/Scenarios/Scenarios.add_item(scenario.get_file().get_basename())


func _on_Scenarios_item_selected(index: int) -> void:
	currentScenario = $Play/Selection/Scenarios/Scenarios.get_item_text(index)

	var scenario = load(world_config.scenarios[index])

	$Play/Info/Description.text = tr(scenario.description)
	$Play/Info/Info/Duration.text = "%s: %d min" % [tr("MENU_DURATION"), scenario.duration]
	$Play/Selection/Trains.show()
	$Play/Info/Info/EasyMode.hide()
	update_train_list()

	# Search and preselect train from scenario:
	$Play/Selection/Trains/Trains.unselect_all()
	var preferredTrain: String = scenario.trains.get("Player", {}).get("PreferredTrain", "")
	if not preferredTrain.empty():
		for i in range(ContentLoader.repo.trains.size()):
			if ContentLoader.repo.trains[i].find(preferredTrain) != -1:
				$Play/Selection/Trains/Trains.select(i)
				_on_Trains_item_selected(i)


func _on_Trains_item_selected(index: int) -> void:
	currentTrain = ContentLoader.repo.trains[index]
	Root.checkAndLoadTranslationsForTrain(currentTrain.get_base_dir())
	# FIXME: this should not happen in the menu. The trains can get huge, so we should
	# add a resource holding information about the trains
	var train: Spatial = load(currentTrain).instance()
	Logger.vlog("Current Train: "+currentTrain)
	$Play/Info/Description.text = tr(train.description)
	$Play/Info/Info/ReleaseDate.text = tr("MENU_RELEASE")+": "+ train.releaseDate
	$Play/Info/Info/Author.text = tr("MENU_AUTHOR")+": "+ train.author
	$Play/Info/Screenshot.texture = _make_image(train.screenshotPath)
	var electric: String = tr("YES")
	if not train.electric:
		electric = tr("NO")
	$Play/Info/Info/Duration.text = tr("MENU_ELECTRIC")+ ": " + electric
	if not Root.mobile_version:
		$Play/Info/Info/EasyMode.show()
	else:
		$Play/Info/Info/EasyMode.pressed = true
	train.queue_free()


func _make_image(path: String) -> Texture:
	var dir := Directory.new()
	if dir.open("res://") == OK and dir.file_exists(path + ".import"):
		screenshot_texture = load(path)
	else:
		Logger.warn("Cannot find image path", path)
		var img := Image.new()
		img.create(1, 1, false, Image.FORMAT_RGB8)
		img.fill(Color.black)
		screenshot_texture = ImageTexture.new()
		screenshot_texture.create_from_image(img)
	return screenshot_texture
