class_name ExitOnFinish extends Node

@export var car: Car
@export var progress: TrackProgress
@export var model: Node3D

@export var leap_height := 5
## How far forward the model travels over the whole leap.
@export var leap_distance := 5.0
## How far below the road the model ends, so it disappears "into the water".
@export var dive_depth := 20.0
@export var leap_seconds := 2
@export var leap_pitch_degrees := 45.0

## Share of the leap spent rising; the rest is the fall.
const RISE_SHARE := 0.4
const PITCH_CHANGE_SECONDS := 0.4

func _ready() -> void:
	progress.finished.connect(_on_finished)


func _on_finished(_car: Car) -> void:
	car.remove_from_play()
	_leap()


func _leap() -> void:
	var start_position := model.position
	# The model faces -Z (the front wheels are at negative Z), so forward is Vector3.FORWARD.
	var half_forward_left := (Vector3.FORWARD + Vector3.LEFT) * leap_distance * 0.5
	var peak_position := start_position + half_forward_left + Vector3.UP * leap_height
	var end_position := start_position + half_forward_left * 2.0 + Vector3.DOWN * dive_depth

	var rise_seconds := leap_seconds * RISE_SHARE
	var fall_seconds := leap_seconds - rise_seconds
	var pitch := deg_to_rad(leap_pitch_degrees)

	var tween := create_tween()

	# Rise: quick off the road, slowing at the top. Nose tilts up.
	var rise := tween.tween_property(model, "position", peak_position, rise_seconds)
	rise.set_trans(Tween.TRANS_QUAD)
	rise.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(model, "rotation:x", pitch, rise_seconds)

	# Fall: slow at the top, speeding into the water. Nose tilts down.
	var fall := tween.tween_property(model, "position", end_position, fall_seconds)
	fall.set_trans(Tween.TRANS_QUAD)
	fall.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(model, "rotation:x", -pitch, PITCH_CHANGE_SECONDS)

	tween.tween_callback(_on_leap_finished)


func _on_leap_finished() -> void:
	car.visible = false
