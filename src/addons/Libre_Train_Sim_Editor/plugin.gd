tool
extends EditorPlugin

var railBuilder
var railAttachements
var configuration
var eds = get_editor_interface().get_selection()
#var fileSelecting = ""
#var fileResult = ""
#var fileDialog

func _process(delta):
	configuration.world = get_editor_interface().get_edited_scene_root()

#	if fileSelecting != "":
#		var fileDialog = EditorFileDialog.new()
#		get_parent().add_child(fileDialog)
#		fileDialog =
#		fileDialog.popup_centered(Vector2(10,10))
#		fileSelecting = ""

func _enter_tree():
	# Initialization of the plugin goes here
	railBuilder = preload("res://addons/Libre_Train_Sim_Editor/Docks/RailBuilder/RailBuilder.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, railBuilder)

	railBuilder.world = get_editor_interface().get_edited_scene_root()
	railBuilder.eds = eds



	railAttachements = preload("res://addons/Libre_Train_Sim_Editor/Docks/RailAttachments/RailAttachments.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, railAttachements)
	railAttachements.world = get_editor_interface().get_edited_scene_root()
	railAttachements.eds = eds
	railAttachements.pluginRoot = self

	eds.connect("selection_changed", self, "_on_selection_changed")

	configuration = preload("res://addons/Libre_Train_Sim_Editor/Docks/Configuration/Configuration.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, configuration)
	configuration.world = get_editor_interface().get_edited_scene_root()

	pass

func _exit_tree():
	remove_control_from_docks(railBuilder)
	railBuilder.free()

	remove_control_from_docks(railAttachements)
	railAttachements.free()

	remove_control_from_docks(configuration)
	configuration.free()

	# Clean-up of the plugin goes here
	pass




func _on_selection_changed():
	railBuilder.world = get_editor_interface().get_edited_scene_root()
	railAttachements.world = get_editor_interface().get_edited_scene_root()
	# Returns an array of selected nodes
	var selected = eds.get_selected_nodes()

	if not selected.empty():
		# Always pick first node in selection
		railBuilder.update_selected_rail(selected[0])
		railAttachements.update_selected_rail(selected[0])

