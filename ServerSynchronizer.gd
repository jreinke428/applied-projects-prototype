extends Node

@export var node_path: NodePath
@export var properties: Array[String]
@onready var node = get_node(node_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	ServerConnection.synchronize.connect(_synchronize)
	if node.name == ServerConnection.session.user_id: $Timer.start()
	
func _synchronize(from, data):
	if node.name == from:
		for property in properties:
			node.set(property, data[property] if property != 'position' else Vector2(data[property].x, data[property].y))

func _on_timer_timeout():
	var data = {}
	for property in properties:
		data[property] = node.get(property) if property != 'position' else {'x': node.position.x, 'y': node.position.y}
	ServerConnection.send_synchronize(data)
