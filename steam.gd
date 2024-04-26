extends Node

signal members_update(members)
signal lobbies_update(lobbies)
signal synchronize(from, data)
signal voice(from, data)

var game_key = "2y88rJjVCb"
var lobby_id = 0
var lobby_name = ""
var lobby_members = []
var is_host = false
var steam_id: int = 0
var steam_username: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	#Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	#Steam.lobby_message.connect(_on_lobby_message)
	#Steam.persona_state_change.connect(_on_persona_change)
	Steam.steamInit(false, 480)
	
	if !Steam.isSteamRunning():
		print("Error: Steam not running")
		return
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getFriendPersonaName(steam_id)
	
func _process(_delta: float) -> void:
	Steam.run_callbacks()
	
	# If the player is connected, read packets
	if lobby_id > 0:
		for pack in Steam.getAvailableP2PPacketSize(): read_p2p_packet() # movement
		for pack in Steam.getAvailableP2PPacketSize(1): read_p2p_packet(1) # voice
		
func read_p2p_packet(channel: int = 0) -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(channel)

	# There is a packet
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, channel)

		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var packet_sender: int = this_packet['steam_id_remote']

		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))

		# Append logic here to deal with packet data
		if readable_data.has('synchronize'): synchronize.emit(packet_sender, readable_data)
		if readable_data.has('voice'): voice.emit(packet_sender, readable_data['data'])
		
func send_p2p_packet(target: int, packet_data: Dictionary, send_type: int = Steam.P2P_SEND_UNRELIABLE, channel: int = 0) -> void:
	# Create a data array to send the data through
	var this_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	if packet_data.has('voice'):
		print('before ',var_to_bytes(packet_data).size())
		print('fater ',this_data.size())
	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for this_member in lobby_members:
				if this_member['steam_id'] != steam_id:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)

	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, this_data, send_type, channel)
	
func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	make_p2p_handshake()

func _on_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)

	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")

	send_p2p_packet(0, {"message": "handshake", "from": steam_id})

func create_lobby(this_lobby_name) -> void:
	if lobby_id == 0:
		lobby_name = this_lobby_name
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
		is_host = true

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", lobby_name)
		Steam.setLobbyData(lobby_id, "game_key", game_key)

		get_tree().change_scene_to_file("res://ui/Lobby.tscn")
		
func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()

	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})

	members_update.emit(lobby_members)

func get_server_ip():
	return Steam.getLobbyGameServer(lobby_id).ip

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	get_lobby_members()

func request_lobbies():
	Steam.addRequestLobbyListStringFilter("game_key", game_key, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_match_list(these_lobbies: Array) -> void:
	var lobbies = []
	
	for lobby in these_lobbies:
		lobbies.append({'id': lobby, 'name': Steam.getLobbyData(lobby, "name"), 'num_members': Steam.getNumLobbyMembers(lobby)})
	
	lobbies_update.emit(lobbies)
	
func join_lobby(this_lobby_id):
	Steam.joinLobby(this_lobby_id)
	
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		get_lobby_members()
		make_p2p_handshake()
		get_tree().change_scene_to_file("res://ui/Lobby.tscn")
		
func start_game():
	Steam.setLobbyGameServer(lobby_id, '127.0.0.1', 1000, 480)
	
