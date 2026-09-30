extends Control

@onready var _connect_button: Button = %ConnectButton
@onready var _connect_status: Label = %ConnectStatusLabel
@onready var _start_button: Button = %StartButton
@onready var _forget_login_button: Button = %ForgetLoginButton

func _ready() -> void:
	_connect_button.pressed.connect(_on_connect_pressed)
	_connect_status.text = "Not connected"
	Twitch.login_completed.connect(_on_login_completed)
	Twitch.login_failed.connect(_on_login_failed)
	_start_button.pressed.connect(_on_start_pressed)
	_forget_login_button.pressed.connect(_on_forget_login_pressed)
	_forget_login_button.disabled = !Twitch.is_logged_in
	# A saved login may have finished before this screen loaded.
	if Twitch.is_logged_in:
		_on_login_completed(Twitch.user_login)
	
func _on_connect_pressed() -> void:
	_connect_button.disabled = true
	_forget_login_button.disabled = false
	_connect_status.text = "Connecting…"
	Twitch.start_login()
	
func _on_login_completed(user_login: String) -> void:
	_connect_button.disabled = true
	_forget_login_button.disabled = false
	_connect_status.text = "Connected as %s" % user_login

func _on_login_failed() -> void:
	_connect_button.disabled = false
	_forget_login_button.disabled = true
	_connect_status.text = "Connection failed"

## Switching account needs a restart: chat stays on the current account
## until the game closes.
func _on_forget_login_pressed() -> void:
	Twitch.forget_login()
	_forget_login_button.disabled = true
	_connect_status.text = "Login cleared - restart to switch account"

func _on_start_pressed() -> void:
	var game = Registration.create()
	MYDSession.shuffle_tracks()
	get_tree().change_scene_to_node(game)
