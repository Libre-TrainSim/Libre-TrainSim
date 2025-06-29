class_name SizeChanger
extends Separator


enum Side {
	TOP = MARGIN_TOP,
	LEFT = MARGIN_LEFT,
	BOTTOM = MARGIN_BOTTOM,
	RIGHT = MARGIN_RIGHT
}


@export var drag_side: Side := Side.RIGHT
@export var target_path: NodePath: NodePath


var is_dragging := false


@onready var target := get_node(target_path) as Control


func _ready() -> void:
	assert(target)
	match drag_side:
		Side.RIGHT, Side.LEFT:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Side.TOP, Side.BOTTOM:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE



func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = true
		return

	if mb and !mb.pressed:
		is_dragging = false
		return

	var mm := event as InputEventMouseMotion
	if mm and is_dragging:
		match drag_side:
			Side.RIGHT:
				target.offset_right += mm.position.x
			Side.LEFT:
				target.offset_left += mm.position.x
			Side.TOP:
				target.offset_top += mm.position.y
			Side.BOTTOM:
				target.offset_bottom += mm.position.y
