extends Control


var counter := 0 setget set_counter
var last_counter := 0
var last_frame := 0
var hide_tween: SceneTreeTween = null
var show_tween: SceneTreeTween = null


func _ready() -> void:
	for child in get_children():
		child.connect("mouse_entered", self, "_on_mouse_entered")
		child.connect("mouse_exited", self, "_on_mouse_exited")


func show_names() -> void:
	if is_instance_valid(show_tween):
		show_tween.kill()
	if is_instance_valid(hide_tween):
		hide_tween.kill()
	show_tween = get_tree().create_tween()
	show_tween.tween_interval(0.5)
	show_tween.tween_property(self, @"rect_size:x", 180.0, 0.2) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)


func hide_names() -> void:
	if is_instance_valid(hide_tween):
		hide_tween.kill()
	if is_instance_valid(show_tween):
		show_tween.kill()
	hide_tween = get_tree().create_tween()
	hide_tween.tween_interval(0.1)
	hide_tween.tween_property(self, @"rect_size:x", 30.0, 0.2) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)


func _on_mouse_entered() -> void:
	self.counter += 1
	yield(get_tree(), "idle_frame")
	if counter == 1 and last_counter == 0:
		show_names()


func _on_mouse_exited() -> void:
	self.counter -= 1
	yield(get_tree(), "idle_frame")
	if counter == 0 and last_counter == 1:
		hide_names()


func set_counter(value: int) -> void:
	if last_frame == Engine.get_idle_frames():
		counter = value
		return
	last_frame = Engine.get_idle_frames()
	last_counter = counter
	counter = value
