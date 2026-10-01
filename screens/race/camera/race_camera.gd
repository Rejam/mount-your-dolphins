class_name RaceCamera extends Camera3D
## Follows one car at a time and orbits around it.
## Controls:
##   camera_next / camera_prev (E/Q, arrow keys) - cycle cars
##   Right mouse drag                              - orbit
##   Mouse wheel                                   - zoom
##   camera_reset (R)                              - reset the view

const POSITION_SMOOTHING := 8.0
const HEADING_SMOOTHING := 3.0
const ORBIT_SENSITIVITY := 0.3
const ZOOM_STEP := 1.10
const PAN_ZOOM_STEP := 1.01

signal user_changed_camera_target(target: Node3D)

@export var distance := 8.0
@export var min_distance := 3.0
@export var max_distance := 30.0
## Degrees above the horizon. 90 = straight down.
@export_range(5.0, 89.0) var pitch_deg := 55.0
@export_range(5.0, 89.0) var min_pitch_deg := 10.0
@export_range(5.0, 89.0) var max_pitch_deg := 89.0
## Orbit angle around the car, in degrees. 0 = directly behind it.
@export var yaw_deg := 0.0

var targets: Array[Node3D] = []
var current_target: Node3D

var _focus := Vector3.ZERO
var _heading := 0.0
var _orbiting := false
var _has_focus := false
var _defaults := {
	"distance": null,
	"pitch_deg": null,
	"yaw_deg": null
}


func _ready() -> void:
	_defaults = {
		"distance": distance,
		"pitch_deg": pitch_deg,
		"yaw_deg": yaw_deg
	}
	# Moved every rendered frame, so it follows the cars' interpolated
	# transforms itself rather than being interpolated by the engine.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	if current_target == null:
		return

	# Use the interpolated transform so the camera matches what's rendered.
	var target_xform := current_target.get_global_transform_interpolated()
	var car_heading := _heading_of(target_xform)
	if not _has_focus:
		_focus = target_xform.origin
		_heading = car_heading
		_has_focus = true
	else:
		_focus = _focus.lerp(target_xform.origin, 1.0 - exp(-POSITION_SMOOTHING * delta))
		_heading = lerp_angle(_heading, car_heading, 1.0 - exp(-HEADING_SMOOTHING * delta))

	var yaw := deg_to_rad(yaw_deg) + _heading
	var orbit := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -deg_to_rad(pitch_deg))
	global_transform = Transform3D(orbit, _focus + orbit * Vector3(0.0, 0.0, distance))


## Give the camera a list of targets
func set_targets(list: Array) -> void:
	targets.assign(list)
	if targets.is_empty():
		current_target = null
		return
	if current_target in targets:
		return
	select(targets[0])


func select(target: Node3D) -> void:
	current_target = target


func cycle(step: int) -> void:
	if targets.is_empty():
		return
	# get current index and add step. wrap to prevent out of bounds error
	var current_index := targets.find(current_target)
	# target not found so just go to first in targets
	if current_index == -1:
		select_by_user(targets[0])
		return
	var new_index := current_index + step
	var wrapped_new_index := wrapi(new_index, 0, targets.size())
	var new_target := targets[wrapped_new_index]
	select_by_user(new_target)


func select_by_user(target: Node3D) -> void:
	select(target)
	user_changed_camera_target.emit(target)
	

func reset_view() -> void:
	set_view(_defaults.distance, _defaults.pitch_deg, _defaults.yaw_deg)


func set_view(new_distance: float, new_pitch_deg: float, new_yaw_deg: float) -> void:
	distance = clampf(new_distance, min_distance, max_distance)
	pitch_deg = clampf(new_pitch_deg, min_pitch_deg, max_pitch_deg)
	yaw_deg = wrapf(new_yaw_deg, 0, 360)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_next"):
		cycle(1)
	elif event.is_action_pressed("camera_prev"):
		cycle(-1)
	elif event.is_action_pressed("camera_reset"):
		reset_view()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_orbiting = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_in(ZOOM_STEP)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_out(ZOOM_STEP)
	elif event is InputEventPanGesture:
		if event.delta.y < 0:
			_zoom_in(PAN_ZOOM_STEP)
		elif event.delta.y > 0:
			_zoom_out(PAN_ZOOM_STEP)
	elif event is InputEventMouseMotion and _orbiting:
		yaw_deg -= event.relative.x * ORBIT_SENSITIVITY
		pitch_deg = clampf(pitch_deg + event.relative.y * ORBIT_SENSITIVITY, min_pitch_deg, max_pitch_deg)


func _zoom_in(step: float) -> void:
	distance = clampf(distance / step, min_distance, max_distance)


func _zoom_out(step: float) -> void:
	distance = clampf(distance * step, min_distance, max_distance)


## Yaw angle of a car's forward (-Z) direction.
func _heading_of(xform: Transform3D) -> float:
	var forward := -xform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.01:
		return _heading
	return atan2(-forward.x, -forward.z)
