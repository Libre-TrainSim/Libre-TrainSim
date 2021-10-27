extends Panel

var selected_track: String = ""
var selected_scenario: String = ""
var selected_route: String = ""
var selected_time: int = -1
var selected_train: String = ""


func show() -> void:
	update_tracks()
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
		text += " > " + Math.time_seconds2String(selected_time)

	$V/Breadcrumb.text = text


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





func _on_Trackst_item_selected(index) -> void:
	selected_track = ContentLoader.repo.worlds[index]
	Root.checkAndLoadTranslationsForTrack(selected_track.get_file().get_basename())
	var save_path: String = ContentLoader.repo.worlds[index].get_basename() + ".trackinfo"
	$jSaveModule.set_save_path(save_path)

	$V/Tracks/H/Information.show()
	var author_text = tr("MENU_AUTHOR") + ": " + $jSaveModule.get_value("author", "-")
	var release_text = tr("MENU_RELEASE") + ": " + String($jSaveModule.get_value("release_date", ["", "-"])[1]) + " " + String($jSaveModule.get_value("release_date", ["", "", ""])[2])
	$V/Tracks/H/Information/V/RichTextLabel.text = "%s\n%s\n\n%s" % [ author_text, release_text, tr($jSaveModule.get_value("description", ""))]
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


func _on_Tracks_item_activated(index) -> void:
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


func update_scenarios() -> void:
	update_breadcrumb()
	$V/Scenarios/ItemList.clear()
	var scenarios = ContentLoader.get_scenarios_for_track(selected_track)
	if scenarios.size() == 1:
		selected_scenario = scenarios[0]
		$V/Scenarios.hide()
		$V/Routes.show()
		update_routes()

	for scenario in scenarios:
		$V/Scenarios/ItemList.add_item(scenario.get_file().get_basename())


func _on_Scenarios_Back_pressed():
	selected_scenario = ""
	update_breadcrumb()
	$V/Scenarios.hide()
	$V/Tracks.show()


func _on_Scenarios_Select_pressed():
	if $V/Scenarios/ItemList.get_selected_items().size() != 1:
		return
	var scenarios = ContentLoader.get_scenarios_for_track(selected_track)
	selected_scenario = scenarios[$V/Scenarios/ItemList.get_selected_items()[0]]
	$V/Scenarios.hide()
	$V/Routes.show()
	update_routes()


func _on_Scenarios_item_activated(index):
	_on_Scenarios_Select_pressed()


func update_routes():
	update_breadcrumb()
	$V/Routes/ItemList.clear()
	print(selected_scenario)
	$ScenarioManager.set_save_path(selected_scenario)
	var routes = $ScenarioManager.get_available_route_names()


	for route_name in routes:
		if $ScenarioManager.is_route_playable(route_name):
			$V/Routes/ItemList.add_item(route_name)

	if $V/Routes/ItemList.get_item_count() == 1:
		selected_route = $V/Routes/ItemList.get_item_text(0)
		$V/Routes.hide()
		$V/Times.show()
		update_times()

func _on_Routes_Back_pressed():
	selected_route = ""
	update_breadcrumb()
	$V/Routes.hide()
	$V/Scenarios.show()


func _on_Routes_Select_pressed():
	if $V/Routes/ItemList.get_selected_items().size() != 1:
		return
	var routes = $ScenarioManager.get_available_route_names()
	selected_route = routes[$V/Routes/ItemList.get_selected_items()[0]]
	$V/Routes.hide()
	$V/Times.show()
	update_times()


func _on_Routes_ItemList_item_activated(index):
	_on_Routes_Select_pressed()




func update_times():
	update_breadcrumb()
	$V/Times/ItemList.clear()

	var times = $ScenarioManager.get_available_start_times_of_route(selected_route)

	if times.size() == 1:
		selected_time = times[0]
		$V/Times.hide()
		$V/Trains.show()
		update_trains()

	for time in times:
		$V/Times/ItemList.add_item(Math.time_seconds2String(time))
	pass

func _on_Times_Select_pressed():
	if $V/Times/ItemList.get_selected_items().size() != 1:
		return
	var times = $ScenarioManager.get_available_start_times_of_route(selected_route)
	selected_time = times[$V/Times/ItemList.get_selected_items()[0]]
	$V/Times.hide()
	$V/Trains.show()
	update_trains()

func _on_Times_ItemList_item_activated(index):
	_on_Times_Select_pressed()


func _on_Times_Back_pressed():
	selected_time = -1
	update_breadcrumb()
	$V/Times.hide()
	$V/Routes.show()


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

	var result: String =  ContentLoader.find_train_path($ScenarioManager.get_route_data()[selected_route].general_settings.train_name)
	if result != "":
		var index = ContentLoader.repo.trains.find(result)
		$V/Trains/H/ItemList.select(index)
		_on_Trains_item_selected(index)


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


func _on_Trains_Play_pressed():
	load_game()


func _on_Trains_item_activated(index):
	_on_Trains_Play_pressed()


func load_game():
	Root.current_track = selected_track
	Root.current_scenario = selected_scenario
	Root.selected_route = selected_route
	Root.selected_time = selected_time
	Root.selected_train = selected_train
	Root.EasyMode = $V/Trains/H/V/EasyMode/CheckButton.pressed
	hide()

	LoadingScreen.load_world(selected_track, $V/Tracks/H/Information/V/Image.texture)
