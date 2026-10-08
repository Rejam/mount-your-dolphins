extends Control

@onready var _start_button: Button = %StartButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	var game = Registration.create()
	MYDSession.prepare_playlist()
	get_tree().change_scene_to_node(game)
