extends Viewport


signal texture_finished(path)
signal group_finished


var scene_root: Node = null


onready var camera := $Camera as Camera
onready var bounds := AABB()


func _ready() -> void:
	if ProjectSettings["game/debug/editor_save_thumbnails"]:
		var dir := Directory.new()
		if !dir.dir_exists("user://debug/"):
			var _err := dir.make_dir_recursive("user://debug/")


func position_camera() -> void:
	camera.translation = bounds.grow(2).end
	camera.look_at(bounds.get_center(), Vector3.UP)


func create_texture(scene_path: String, objects: ObjectGroup) -> void:
	var img := get_texture().get_data()
	img.flip_y()
	var texture := ImageTexture.new()
	texture.create_from_image(img)
	objects.thumbnails[scene_path] = texture
	if ProjectSettings["game/debug/editor_save_thumbnails"]:
		var _err := img.save_png("user://debug/%s.png" % scene_path.get_file())
	emit_signal("texture_finished", scene_path)


func setup_scene(scene: PackedScene) -> bool:
	if !scene.can_instance():
		Logger.err("Can't instantiate scene", scene)
		return false
	scene_root = scene.instance()
	add_child(scene_root)
	bounds = calculate_bounds(scene_root)
	return true


func calculate_bounds(node: Node) -> AABB:
	var aabb := AABB()
	if node is VisualInstance:
		aabb = (node as VisualInstance).get_transformed_aabb()

	for child in node.get_children():
		aabb = aabb.merge(calculate_bounds(child))
	return aabb


## Coroutine! Use with yield(generate_thumbnails, "completed")
func generate_thumbnails(objects: ObjectGroup) -> void:
	for scene in objects.scenes:
		if !setup_scene(scene):
			continue
		position_camera()
		yield(VisualServer, "frame_post_draw")
		create_texture(scene.resource_path, objects)
		scene_root.queue_free()
		yield(VisualServer, "frame_post_draw")
	emit_signal("group_finished")
