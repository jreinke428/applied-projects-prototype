extends Control

func _on_start_button_pressed():
	ServerConnection.join_match($VBoxContainer/MatchName.text, $VBoxContainer/Username.text)
