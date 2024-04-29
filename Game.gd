extends Node2D

@export var player_scene: PackedScene
var spawn_position: Vector2
var spawn_radius = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	if !multiplayer.is_server(): return
	Signals.world_loaded.connect(call_close_loading)
	spawn_position = Vector2(randf_range(350, 450), randf_range(350, 450))
	for id in ServerConnection.players:
		var player = player_scene.instantiate()
		player.name = str(id)
		call_deferred("add_child", player)
		await get_tree().create_timer(0.1).timeout
		player.set_pos.rpc(Vector2(randf_range(spawn_position.x-spawn_radius, spawn_position.x+spawn_radius), randf_range(spawn_position.y-spawn_radius, spawn_position.y+spawn_radius)))

func _on_button_toggled(toggled_on):
	Signals.voice_chat.emit(toggled_on)
	
func call_close_loading():
	close_loading_overlay.rpc()

@rpc("any_peer", "call_local", "reliable")
func close_loading_overlay():
	$UILayer/LoadingOverlay.visible = false
