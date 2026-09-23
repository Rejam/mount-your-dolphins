extends VehicleBody3D
## A car that drives toward whatever point it's given. Knows nothing about tracks.

@export var max_engine_force := 90.0
@export var max_brake := 3.0
@export var max_steer := 0.55
@export var steer_rate := 3.0
## Pull toward the surface while the wheels are touching it, in m/s².
## Lets cars hold steep ramps and loops. It stops once they leave the
## surface, so pushing past the limit sends them flying.
@export var stickiness := 15.0

## The car's front is -Z, so engine force is negated to drive forward.
const DRIVE_SIGN := -1.0

var _wheels: Array[VehicleWheel3D] = []


func _ready() -> void:
	# A low centre of mass keeps the car from rolling in corners.
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.15, 0.0)
	for child in get_children():
		if child is VehicleWheel3D:
			_wheels.append(child)


func _physics_process(_delta: float) -> void:
	var touching := 0
	for wheel in _wheels:
		if wheel.is_in_contact():
			touching += 1
	if touching > 0:
		var grip := float(touching) / _wheels.size()
		apply_central_force(-global_basis.y * mass * stickiness * grip)


func get_speed() -> float:
	return linear_velocity.dot(-global_basis.z)


## Steer toward a world point and hold a target speed. Call every physics frame.
func drive_toward(point: Vector3, target_speed: float, delta: float) -> void:
	var local := to_local(point)
	# Positive steering turns left; with -Z forward, left is -X.
	var desired := atan2(-local.x, -local.z)
	steering = move_toward(steering, clampf(desired, -max_steer, max_steer), steer_rate * delta)

	var speed := get_speed()
	if speed < target_speed:
		engine_force = DRIVE_SIGN * max_engine_force * clampf((target_speed - speed) / 2.0, 0.25, 1.0)
		brake = 0.0
	else:
		engine_force = 0.0
		brake = max_brake * clampf((speed - target_speed) / 2.0, 0.0, 1.0)


## Teleport to a transform and come to a stop.
func reset_to(xform: Transform3D) -> void:
	global_transform = xform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	steering = 0.0
	engine_force = 0.0
	reset_physics_interpolation()
