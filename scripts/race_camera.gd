class_name RaceCamera
extends Camera3D
## Follows one car at a time and orbits around it.
##
## Controls:
##   camera_next / camera_prev (E/Q, arrow keys) - cycle cars
##   1-9                                           - jump to a car
##   Right mouse drag                              - orbit
##   Mouse wheel                                   - zoom
##   camera_reset (R)                              - reset the view

signal target_changed(index: int, target: Node3D)

@export_group("View")
@export var distance := 8.0
@export var min_distance := 3.0
@export var max_distance := 60.0
## Degrees above the horizon. 90 = straight down.
@export_range(5.0, 89.0) var pitch_deg := 55.0
@export_range(5.0, 89.0) var min_pitch_deg := 10.0
@export_range(5.0, 89.0) var max_pitch_deg := 89.0
## Orbit angle around the car, in degrees. 0 = directly behind it.
@export var yaw_deg := 0.0
## Rotate with the car so the orbit angle stays relative to its heading.
## Off = the orbit angle is fixed in world space.
@export var follow_heading := true

@export_group("Feel")
@export var position_smoothing := 8.0
@export var heading_smoothing := 3.0
@export var orbit_sensitivity := 0.3
@export var zoom_step := 1.12

var targets: Array[Node3D] = []
var index := 0

var _focus := Vector3.ZERO
var _heading := 0.0
var _orbiting := false
var _has_focus := false
var _defaults := {}


func _ready() -> void:
	_defaults = {"distance": distance, "pitch_deg": pitch_deg, "yaw_deg": yaw_deg}
	# Moved every rendered frame, so it follows the cars' interpolated
	# transforms itself rather than being interpolated by the engine.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


## Give the camera the cars it can follow.
func set_targets(list: Array) -> void:
	targets.assign(list)
	select(clampi(index, 0, maxi(targets.size() - 1, 0)))


func select(new_index: int) -> void:
	if targets.is_empty():
		return
	index = wrapi(new_index, 0, targets.size())
	target_changed.emit(index, targets[index])


func cycle(step: int) -> void:
	select(index + step)


func current_target() -> Node3D:
	if targets.is_empty():
		return null
	var target := targets[index]
	return target if is_instance_valid(target) else null


func reset_view() -> void:
	distance = _defaults.distance
	pitch_deg = _defaults.pitch_deg
	yaw_deg = _defaults.yaw_deg


func _process(delta: float) -> void:
	var target := current_target()
	if target == null:
		return

	# Use the interpolated transform so the camera matches what's rendered.
	var target_xform := target.get_global_transform_interpolated()
	var car_heading := _heading_of(target_xform)
	if not _has_focus:
		_focus = target_xform.origin
		_heading = car_heading
		_has_focus = true
	else:
		_focus = _focus.lerp(target_xform.origin, 1.0 - exp(-position_smoothing * delta))
		_heading = lerp_angle(_heading, car_heading, 1.0 - exp(-heading_smoothing * delta))

	var yaw := deg_to_rad(yaw_deg) + (_heading if follow_heading else 0.0)
	var orbit := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -deg_to_rad(pitch_deg))
	global_transform = Transform3D(orbit, _focus + orbit * Vector3(0.0, 0.0, distance))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_next"):
		cycle(1)
	elif event.is_action_pressed("camera_prev"):
		cycle(-1)
	elif event.is_action_pressed("camera_reset"):
		reset_view()
	elif event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.keycode - KEY_0
		if n >= 1 and n <= 9 and n <= targets.size():
			select(n - 1)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_orbiting = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					distance = clampf(distance / zoom_step, min_distance, max_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					distance = clampf(distance * zoom_step, min_distance, max_distance)
	elif event is InputEventMouseMotion and _orbiting:
		yaw_deg -= event.relative.x * orbit_sensitivity
		pitch_deg = clampf(pitch_deg + event.relative.y * orbit_sensitivity, min_pitch_deg, max_pitch_deg)


## Yaw angle of a car's forward (-Z) direction.
func _heading_of(xform: Transform3D) -> float:
	var forward := -xform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.01:
		return _heading
	return atan2(-forward.x, -forward.z)
