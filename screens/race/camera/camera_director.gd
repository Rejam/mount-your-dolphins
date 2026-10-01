class_name CameraDirector extends Node

enum Mode { AUTO, MANUAL }

@export var camera: RaceCamera
@export var standings: Standings

@export var auto_distance := 12.0
@export var auto_pitch_deg := 35.0
@export var auto_yaw_deg := 160.0

var mode := Mode.AUTO
var _saved_manual_camera_settings := {
	"distance": null,
	"pitch_deg": null,
	"yaw_deg": null
}

func _ready() -> void:
	camera.user_changed_camera_target.connect(_on_user_changed_camera_target)
	_enter_auto(true)


func _process(_delta: float) -> void:
	var racing_order := standings.still_racing_order
	var racing_order_cars: Array[Car] = [] 
	for place in racing_order:
		racing_order_cars.append(place.car)

	camera.set_targets(racing_order_cars)

	if mode == Mode.AUTO:
		_handle_auto_mode(racing_order_cars)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_auto_mode"):
		_enter_auto()


func _handle_auto_mode(order: Array[Car]) -> void:
	if order.is_empty():
		return
	var leader := order[0]
	camera.select(leader)



func _save_manual_camera_settings(distance: float, pitch_deg: float, yaw_deg: float) -> void:
	_saved_manual_camera_settings = {
		"distance": distance,
		"pitch_deg": pitch_deg,
		"yaw_deg": yaw_deg,
	}


func _on_user_changed_camera_target(_target: Node3D) -> void:
	_enter_manual()


func _enter_auto(force_auto = false) -> void:
	if mode == Mode.AUTO and not force_auto:
		return
	mode = Mode.AUTO
	_save_manual_camera_settings(camera.distance, camera.pitch_deg, camera.yaw_deg)
	camera.set_view(auto_distance, auto_pitch_deg, auto_yaw_deg)


func _enter_manual() -> void:
	if mode == Mode.MANUAL:
		return
	mode = Mode.MANUAL
	var saved_distance: float = _saved_manual_camera_settings.distance
	var saved_pitch_deg: float = _saved_manual_camera_settings.pitch_deg
	var saved_yaw_deg: float = _saved_manual_camera_settings.yaw_deg
	camera.set_view(saved_distance, saved_pitch_deg, saved_yaw_deg)
