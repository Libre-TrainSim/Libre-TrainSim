class_name PassengerPathNode
extends Spatial

export (Array, NodePath) var connections: Array = []  # array of node paths
var connection_nodes := []  # array of nodes

enum Type {
	PATH_NODE = 0,
	DOOR = 1,
	SEAT = 2,
}
var type: int = Type.PATH_NODE

func _ready():
	$MeshInstance.queue_free()
	for connection in connections:
		var conn = get_node(connection)
		if conn == null:
			Logger.warn("Connection has wrong NodePath!", self)
			continue
		connection_nodes.append(conn)
		if conn.type != Type.PATH_NODE:
			conn.connection_nodes.append(self)
