tool
class_name AabbToCollider
extends VisualInstance


export var generate := false setget set_generate
export var target: NodePath


func generate_collider() -> void:
	var static_body := StaticBody.new()
	static_body.name = "SelectCollider"
	var collision_shape := CollisionShape.new()
	collision_shape.name = "AabbShape"
	collision_shape.shape = BoxShape.new()
	collision_shape.shape.extents = get_transformed_aabb().size * 0.5
	collision_shape.translation = get_transformed_aabb().size * 0.5

	var target_node = get_node_or_null(target)
	if target_node:
		target_node.add_child(static_body, true)
		static_body.owner = target_node
	else:
		self.owner.add_child(static_body, true)
		static_body.owner = self.owner

	static_body.global_transform.origin = get_transformed_aabb().position
	static_body.add_child(collision_shape, true)
	collision_shape.owner = static_body.owner


func set_generate(val: bool) -> void:
	if !val:
		return
	generate_collider()
	generate = false
