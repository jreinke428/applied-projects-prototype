# goes onto an audio_controller with an AudioStreamPlayer (mic input) child
extends Node

@export var host_path: NodePath
@onready var host = get_node(host_path)
@onready var input : AudioStreamPlayer2D = $Input
@onready var idx : int = AudioServer.get_bus_index("Record")
@onready var effect : AudioEffectCapture = AudioServer.get_bus_effect(idx, 0)
@onready var output := $Output
@onready var playback : AudioStreamGeneratorPlayback = output.get_stream_playback()
@onready var listener := $Listener
@onready var opus_encoder = load("res://OpusCompression.cs").new()
var encode_buffer = PackedFloat32Array()
var opus_frame_size = 480

func _ready() -> void:
	if !is_multiplayer_authority(): return
	Signals.voice_chat.connect(_voice_chat)
	input.stream = AudioStreamMicrophone.new()
	input.play()
	listener.make_current()

func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	process_input()
	encode_and_send()

func process_input():
	var voice_data := effect.get_buffer(512)
	effect.clear_buffer()
	var data = PackedFloat32Array()
	data.resize(voice_data.size())
	var max_value := 0.0
	for i in range(voice_data.size()):
		var value = (voice_data[i].x + voice_data[i].y) / 2
		max_value = max(value, max_value)
		data[i] = value
	if max_value < 0.01: return
	encode_buffer.append_array(data)

func encode_and_send():
	while encode_buffer.size() >= opus_frame_size:
		voice.rpc(opus_encoder.encode(encode_buffer.slice(0, opus_frame_size)))
		encode_buffer = encode_buffer.slice(opus_frame_size)
		
func _voice_chat(enabled):
	input.playing = enabled

@rpc("authority", "call_remote", "reliable")
func voice(encoded):
	if multiplayer.get_remote_sender_id() == host.name.to_int():
		host.toggle_speaking(true)
		$VoiceUI.start()
		var decoded = opus_encoder.decode(encoded)
		for i in decoded:
			playback.push_frame(Vector2(i, i)) 

func _on_voice_ui_timeout():
	host.toggle_speaking(false)
