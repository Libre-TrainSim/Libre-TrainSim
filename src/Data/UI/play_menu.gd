extends Panel

var selected_track: String = ""
var selected_scenario: String = ""
var selected_route: String = ""
var selected_time: int = -1
var selected_train: String = ""

var world_config: WorldConfig # config of selected world
var loaded_scenario: TrackScenario = null
var loaded_route: ScenarioRoute = null


func _ready() -> void:
	$V/Tracks.connect("visibility_changed", self, "_on_menu_visibility_changed")
	$V/Scenarios.connect("visibility_changed", self, "_on_menu_visibility_changed")
	$V/Routes.connect("visibility_changed", self, "_on_menu_visibility_changed")
	$V/Times.connect("visibility_changed", self, "_on_menu_visibility_changed")
	$V/Trains.connect("visibility_changed", self, "_on_menu_visibility_changed")


func show() -> void:
	update_tracks()
	$V/Tracks/H/ItemList.grab_focus()
	.show()


func update_breadcrumb():
	var text = ""
	if selected_track != "":
		text += selected_track.get_file().get_basename()
	if selected_scenario != "":
		text += " > " + selected_scenario.get_file().get_basename()
	if selected_route != "":
		text += " > " + selected_route
	if selected_time != -1:
		text += " > " + Math.seconds_to_string(selected_time)

	$V/Breadcrumb.text = text


func load_game():
	Root.current_track = selected_track
	Root.current_scenario = selected_scenario
	Root.selected_route = selected_route
	Root.selected_time = selected_time
	Root.selected_train = selected_train
	Root.EasyMode = $V/Trains/H/V/EasyMode/CheckButton.pressed
	hide()

	LoadingScreen.load_world(selected_track, $V/Tracks/H/Information/V/Image.texture)


func update_tracks() -> void:
	update_breadcrumb()
	$V/Tracks/H/Information.hide()
	$V/Tracks/H/ItemList.clear()
	if ContentLoader.repo.worlds.size() == 1:
		selected_track = ContentLoader.repo.worlds[0]
		$V/Tracks.hide()
		$V/Scenarios.show()
		update_scenarios()
	for track in ContentLoader.repo.worlds:
		$V/Tracks/H/ItemList.add_item(track.get_file().get_basename())
	$V/Tracks/H/ItemList.select(0)


func update_scenarios() -> void:
	update_breadcrumb()
	$V/Scenarios/ItemList.clear()
	var scenarios = ContentLoader.get_scenarios_for_track(selected_track.get_base_dir())
	if scenarios.size() == 1:
		selected_scenario = scenarios[0]
		loaded_scenario = TrackScenario.load_scenario(selected_scenario)
		$V/Scenarios.hide()
		$V/Routes.show()
		update_routes()

	for scenario in scenarios:
		$V/Scenarios/ItemList.add_item(scenario.get_file().get_basename())
	$V/Scenarios/ItemList.select(0)


func update_routes():
	update_breadcrumb()
	$V/Routes/ItemList.clear()

	var routes = loaded_scenario.routes.keys()
	for route_name in routes:
		if loaded_scenario.is_route_playable(route_name):
			$V/Routes/ItemList.add_item(route_name)
	$V/Routes/ItemList.select(0)

	if $V/Routes/ItemList.get_item_count() == 1:
		selected_route = $V/Routes/ItemList.get_item_text(0)
		loaded_route = loaded_scenario.routes[selected_route]
		$V/Routes.hide()
		$V/Times.show()
		update_times()


func update_times():
	update_breadcrumb()
	$V/Times/ItemList.clear()

	var times = loaded_route.get_start_times()
	if times.size() == 1:
		selected_time = times[0]
		$V/Times.hide()
		$V/Trains.show()
		update_trains()

	for time in times:
		$V/Times/ItemList.add_item(Math.seconds_to_string(time))
	$V/Times/ItemList.select(0)
	pass


func update_trains():
	update_breadcrumb()
	$V/Trains/H/ItemList.clear()
	$V/Trains/H/V/EasyMode.hide()
	$V/Trains/H/V/Information.hide()
	if ContentLoader.repo.trains.size() == 1:
		selected_train = ContentLoader.repo.trains[0]
		load_game()

	for train in ContentLoader.repo.trains:
		$V/Trains/H/ItemList.add_item(train.get_file().get_basename())

	var result: String =  ContentLoader.find_train_path(loaded_route.train_name)
	if result != "":
		var index = ContentLoader.repo.trains.find(result)
		$V/Trains/H/ItemList.select(index)
		_on_Trains_item_selected(index)


func _on_Tracklist_item_selected(index) -> void:
	selected_track = ContentLoader.repo.worlds[index]
	Root.checkAndLoadTranslationsForTrack(selected_track.get_file().get_basename())
	var config_path: String = ContentLoader.repo.worlds[index].get_basename() + "_config.tres"
	world_config = load(config_path)

	$V/Tracks/H/Information.show()
	var author_text = tr("MENU_AUTHOR") + ": " + world_config.author
	var release_text = tr("MENU_RELEASE") + ": " + world_config.get_release_date_string()
	$V/Tracks/H/Information/V/RichTextLabel.text = "%s\n%s\n\n%s" % [ author_text, release_text, tr(world_config.track_description)]
	$V/Tracks/H/Information/V/Image.texture = _make_image(selected_track.get_base_dir() + "/screenshot.png")


func _make_image(path: String) -> Texture:
	var screenshot_texture: Texture
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


func _on_Tracks_item_activated(_index) -> void:
	_on_Tracks_Select_pressed()


func _on_Tracks_Select_pressed() -> void:
	if $V/Tracks/H/ItemList.get_selected_items().size() != 1:
		return
	selected_track = ContentLoader.repo.worlds[$V/Tracks/H/ItemList.get_selected_items()[0]]
	$V/Tracks.hide()
	$V/Scenarios.show()
	update_scenarios()


func _on_Tracks_Back_pressed() -> void:
	update_breadcrumb()
	selected_track = ""
	hide()


func _on_Scenarios_Back_pressed():
	selected_scenario = ""
	loaded_scenario = null
	update_breadcrumb()
	$V/Scenarios.hide()
	$V/Tracks.show()

	if $V/Tracks/H/ItemList.get_item_count() == 1:
		_on_Tracks_Back_pressed()


func _on_Scenarios_Select_pressed():
	if $V/Scenarios/ItemList.get_selected_items().size() != 1:
		return
	var scenarios = ContentLoader.get_scenarios_for_track(selected_track.get_base_dir())
	selected_scenario = scenarios[$V/Scenarios/ItemList.get_selected_items()[0]]
	loaded_scenario = TrackScenario.load_scenario(selected_scenario)
	$V/Scenarios.hide()
	$V/Routes.show()
	update_routes()


func _on_Scenarios_item_activated(_index):
	_on_Scenarios_Select_pressed()


func _on_Routes_Back_pressed():
	selected_route = ""
	update_breadcrumb()
	$V/Routes.hide()
	$V/Scenarios.show()

	if $V/Scenarios/ItemList.get_item_count() == 1:
		_on_Scenarios_Back_pressed()


func _on_Routes_Select_pressed():
	if $V/Routes/ItemList.get_selected_items().size() != 1:
		return
	var routes = loaded_scenario.routes.keys()
	selected_route = routes[$V/Routes/ItemList.get_selected_items()[0]]
	loaded_route = loaded_scenario.routes[selected_route]
	$V/Routes.hide()
	$V/Times.show()
	update_times()


func _on_Routes_ItemList_item_activated(_index):
	_on_Routes_Select_pressed()


func _on_Times_Select_pressed():
	if $V/Times/ItemList.get_selected_items().size() != 1:
		return
	var times = loaded_route.get_start_times()
	selected_time = times[$V/Times/ItemList.get_selected_items()[0]]
	$V/Times.hide()
	$V/Trains.show()
	update_trains()


func _on_Times_ItemList_item_activated(_index):
	_on_Times_Select_pressed()


func _on_Times_Back_pressed():
	selected_time = -1
	update_breadcrumb()
	$V/Times.hide()
	$V/Routes.show()

	if $V/Routes/ItemList.get_item_count() == 1:
		_on_Routes_Back_pressed()


func _on_Trains_item_selected(index):
	selected_train = ContentLoader.repo.trains[index]
	# FIXME: this should not happen in the menu. The trains can get huge, so we should
	# add a resource holding information about the trains
	var train: Spatial = load(selected_train).instance()
	Logger.vlog("Current Train: " + selected_train)

	$V/Trains/H/V/Information.show()
	Root.checkAndLoadTranslationsForTrain(selected_train.get_base_dir())
	var author_text = tr("MENU_AUTHOR") + ": " + train.author
	var release_text = tr("MENU_RELEASE") + ": " + train.releaseDate
	var electric: String = tr("YES")
	if not train.electric:
		electric = tr("NO")
	var electric_text = tr("MENU_ELECTRIC")+ ": " + electric


	$V/Trains/H/V/Information/V/RichTextLabel.text = "%s\n%s\n%s\n\n%s" % [ author_text, release_text, electric_text, tr(train.description)]
	$V/Trains/H/V/Information/V/Image.texture = _make_image(train.screenshotPath)
	train.queue_free()

	if not Root.mobile_version:
		$V/Trains/H/V/EasyMode.show()
	else:
		$V/Trains/H/V/EasyMode/CheckButton.pressed = true


func _on_Trains_Back_pressed():
	selected_train = ""
	update_breadcrumb()
	$V/Trains.hide()
	$V/Times.show()

	if $V/Times/ItemList.get_item_count() == 1:
		_on_Times_Back_pressed()


func _on_Trains_Play_pressed():
	load_game()


func _on_Trains_item_activated(_index):
	_on_Trains_Play_pressed()


func _on_menu_visibility_changed() -> void:
	if $V/Trains.visible:
		$V/Trains/H/ItemList.grab_focus()
	elif $V/Times.visible:
		$V/Times/ItemList.grab_focus()
	elif $V/Routes.visible:
		$V/Routes/ItemList.grab_focus()
	elif $V/Scenarios.visible:
		$V/Scenarios/ItemList.grab_focus()
	elif visible:
		$V/Tracks/H/ItemList.grab_focus()
