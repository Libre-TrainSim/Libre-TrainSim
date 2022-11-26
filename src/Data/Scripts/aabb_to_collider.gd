tool
class_name AabbToCollider
extends Node


export var generate := false setget set_generate
export var target: NodePath


func generate_collider() -> void:
	var static_body := StaticBody.new()
	static_body.name = "SelectCollider"

	var bounds := calculate_bounds(self)

	var collision_shape := CollisionShape.new()
	collision_shape.name = "AabbShape"
	collision_shape.shape = BoxShape.new()
	collision_shape.shape.extents = bounds.size * 0.5
	collision_shape.translation = bounds.size * 0.5

	var target_node = get_node_or_null(target)
	if target_node:
		target_node.add_child(static_body, true)
		static_body.owner = target_node
	else:
		self.owner.add_child(static_body, true)
		static_body.owner = self.owner

	static_body.global_transform.origin = bounds.position
	static_body.add_child(collision_shape, true)
	collision_shape.owner = static_body.owner


func calculate_bounds(node: Node) -> AABB:
	var aabb := AABB()
	if node is VisualInstance:
		aabb = (node as VisualInstance).get_transformed_aabb()

	for child in node.get_children():
		aabb = aabb.merge(calculate_bounds(child))
	return aabb


func set_generate(val: bool) -> void:
	if !val:
		return
	generate_collider()
	generate = false
