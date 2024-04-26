extends Node2D

@export var player_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	if !multiplayer.is_server(): return
	for id in ServerConnection.players:
		var player = player_scene.instantiate()
		player.name = str(id)
		call_deferred("add_child", player)
	

func _on_button_toggled(toggled_on):
	Signals.voice_chat.emit(toggled_on)
