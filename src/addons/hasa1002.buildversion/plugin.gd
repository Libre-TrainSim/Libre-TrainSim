tool
extends EditorPlugin


var running := true
var version_exporter := preload("res://addons/hasa1002.buildversion/version_exporter.gd").new()


func _enter_tree() -> void:
	enable_plugin()
	var interface := get_editor_interface()
	var was_playing := false
	while running:
		yield(interface.get_tree(), "idle_frame")
		if was_playing and !interface.is_playing_scene():
			version_exporter.reset()
		was_playing = interface.is_playing_scene()


func _exit_tree() -> void:
	disable_plugin()


func enable_plugin() -> void:
	running = true
	add_export_plugin(version_exporter)


func disable_plugin() -> void:
	running = false
	version_exporter.reset()
	remove_export_plugin(version_exporter)


func build() -> bool:
	version_exporter.build()
	return true
