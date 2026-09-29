extends Control

@onready var _connect_button: Button = %ConnectButton
@onready var _connect_status: Label = %ConnectStatusLabel
@onready var _start_button: Button = %StartButton

func _ready() -> void:
	_connect_button.pressed.connect(_on_connect_pressed)
	_connect_status.text = "Not connected"
	Twitch.login_completed.connect(_on_login_completed)
	Twitch.login_failed.connect(_on_login_failed)
	_start_button.pressed.connect(_on_start_pressed)
	
func _on_connect_pressed() -> void:
	_connect_button.disabled = true
	_connect_status.text = "Connecting…"
	Twitch.start_login()
	
func _on_login_completed(user_login: String) -> void:
	_connect_status.text = "Connected as %s" % user_login

func _on_login_failed() -> void:
	_connect_button.disabled = false
	_connect_status.text = "Connection failed"

func _on_start_pressed() -> void:
	var game = Registration.create()
	Session.shuffle_tracks()
	get_tree().change_scene_to_node(game)
