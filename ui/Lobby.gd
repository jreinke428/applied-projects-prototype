extends CanvasLayer

var lobby_members

# Called when the node enters the scene tree for the first time.
func _ready():
	ServerConnection.players_updated.connect(display_members)
	display_members(ServerConnection.players)
	$VBoxContainer/Button.visible = multiplayer.is_server()
	
func display_members(members):
	for c in $VBoxContainer/Players.get_children():
		$VBoxContainer/Players.remove_child(c)
		c.queue_free()
		
	for member in members:
		var label: Label = Label.new()
		label.text = members[member].username
		$VBoxContainer/Players.add_child(label)
	
func _on_button_pressed():
	start_match.rpc()
	
@rpc("any_peer", "call_local", "reliable")
func start_match():
	get_tree().change_scene_to_file("res://Game.tscn")
	
