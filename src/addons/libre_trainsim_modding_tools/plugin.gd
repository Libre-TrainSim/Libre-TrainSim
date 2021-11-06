tool
extends EditorPlugin

var dock: Control
var base: Control

func _enter_tree():
	base = get_editor_interface().get_base_control()

	dock = preload("dock.tscn").instance()
	dock.base = base
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)


func _exit_tree() -> void:
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.queue_free()
