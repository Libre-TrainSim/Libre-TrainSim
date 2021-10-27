class_name Map
extends Control

enum MapStatus {
	CLOSED = 0,
	OVERLAY = 1,
	FULL = 2,
}
var map_status: int = MapStatus.CLOSED

func init_for_scenario_editor(world_node : Node):
	set_process_unhandled_key_input(false)
	$ViewportContainer/RailMap.train_world = world_node
	$ViewportContainer.anchor_right = $FullMap.anchor_right
	$ViewportContainer/RailMap.open_full_map()
	show()
	$FullMap.show()
	$OverlayMap.hide()
	map_status = MapStatus.FULL

func _unhandled_key_input(_event):
	if Input.is_action_just_pressed("map_open"):
		map_status = (map_status + 1) % MapStatus.size()
		match map_status:
			MapStatus.CLOSED:
				$ViewportContainer/RailMap.close_map()
				hide()
			MapStatus.OVERLAY:
				$ViewportContainer.anchor_right = $OverlayMap.anchor_right
				$ViewportContainer/RailMap.open_overlay_map()
				show()
				$FullMap.hide()
				$OverlayMap.show()
			MapStatus.FULL:
				$ViewportContainer.anchor_right = $FullMap.anchor_right
				$ViewportContainer/RailMap.open_full_map()
				show()
				$FullMap.show()
				$OverlayMap.hide()
