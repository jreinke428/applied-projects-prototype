extends Node

signal players_updated(players)

var client := Nakama.create_client("defaultkey", "70.57.93.93", 7350, "http")
var device_id = OS.get_unique_id()

var session : NakamaSession 
var socket : NakamaSocket 
var multiplayer_bridge : NakamaMultiplayerBridge
var match_id : String
var players = {}

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
func join_match(match_name, username):
	await authenticate(username)
	multiplayer_bridge.join_named_match(match_name)
	
func authenticate(username):
	session = await client.authenticate_custom_async(str(randi_range(100000, 999999)) + '_' + username, username)
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	multiplayer_bridge = NakamaMultiplayerBridge.new(socket)
	multiplayer_bridge.match_joined.connect(_match_joined)
	multiplayer.multiplayer_peer = multiplayer_bridge.multiplayer_peer

func _match_joined() -> void:
	var my_peer_id := multiplayer.get_unique_id()
	var presence: NakamaRTAPI.UserPresence = multiplayer_bridge.get_user_presence_for_peer(my_peer_id)
	players[my_peer_id] = presence
	match_id = multiplayer_bridge.match_id
	get_tree().change_scene_to_file("res://ui/Lobby.tscn")

func _peer_connected(peer_id: int) -> void:
	var presence: NakamaRTAPI.UserPresence = multiplayer_bridge.get_user_presence_for_peer(peer_id)
	players[peer_id] = presence
	players_updated.emit(players)

func _peer_disconnected(peer_id: int) -> void:
	var player = players.get(peer_id)
	if player != null:
		players.erase(peer_id)
	players_updated.emit(players)
