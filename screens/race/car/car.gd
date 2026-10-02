class_name Car
extends VehicleBody3D
## A car that drives toward whatever point it's given. Knows nothing about tracks.

## car.tscn. Loaded rather than preloaded: car.tscn uses this script, so a
## preload here would be a cyclic reference.
const SCENE_UID := "uid://ch1ph3v6ippq6"
## The car's front is -Z, so engine force is negated to drive forward.
const DRIVE_SIGN := -1.0
## Motorbike layout: one wheel front, one back, on the centre line.
const FRONT_WHEEL_POSITION := Vector3(0.0, 0.25, -0.34)
const BACK_WHEEL_POSITION := Vector3(0.0, 0.25, 0.46)

@export var max_engine_force := 150.0
@export var max_brake := 5.0
@export var max_steer := 0.8
@export var steer_rate := 5.0
@export_range(0.0, 30.0, 1) var stickiness := 20.0
@export var ai_components: Array[Node]

@export_group("Wheels")
@export var tyre_grip := 50.0
@export var wheel_radius := 0.1
@export var suspension_rest_length := 0.14
@export var suspension_travel := 0.1
@export var suspension_stiffness := 200.0
@export var damping_compression := 2.8
@export var damping_relaxation := 3.5

@export_group("Balance")
## How hard the bike springs back upright per radian of lean, in 1/s².
## Too low and bikes topple in bends; too high and hits can't tip them.
@export_range(0.0, 400.0, 5.0) var upright_strength := 50.0
## How much it resists leaning speed, in 1/s.
## Below 2 × √strength (20 at 100) bikes wobble; above it they return slowly.
@export_range(0.0, 50.0, 0.5) var upright_damping := 12.0

@export_group("Bumper")
## Multiplier on how hard the physics hit was. Adds on top of min_kick.
@export_range(0.0, 5.0, 0.5) var bumper_strength := 2.5
## Speed every contact pushes the cars apart with, however gentle the touch.
@export_range(0.0, 10.0, 0.5) var bumper_min_kick := 2.5
## Strongest random spin a hit can cause, in radians per second.
@export_range(0.0, 10.0, 0.5) var bumper_max_spin := 3.0
## Upward pop as a fraction of the push. Lifting the wheels off the road
## stops tyre grip soaking up the push, so hits actually move the car.
@export_range(0.0, 2.0, 0.1) var bumper_lift := 0.9


## Car owner
var racer: RacerEntry
## Filled by _build_wheels() in _ready(); empty before then.
var wheels : Array[VehicleWheel3D]
## True on the grid before GO, so the bike is held from creeping sideways.
var _parked := false

@onready var owner_label: Label3D = %OwnerLabel
@onready var model: Dolphin = $Model


## Makes a new car for a viewer. Add it to the tree, then place it.
static func create(entry: RacerEntry) -> Car:
	var car: Car = load(SCENE_UID).instantiate()
	car.racer = entry
	car.name = "Car_%s" % entry.user_id
	return car


func _ready() -> void:
	# A low centre of mass keeps the car from rolling in corners.
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.15, 0.0)
	owner_label.text = racer.display_name
	model.tint(Color.from_hsv(randf(), 0.6, 1.0))
	_build_wheels()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _parked:
		_stop_sideways_creep(state)


func get_speed() -> float:
	return linear_velocity.dot(-global_basis.z)


## Steer toward a world point and hold a target speed. Call every physics frame.
## power scales the engine, e.g. 1.1 = 10% more acceleration.
func drive_toward(point: Vector3, target_speed: float, delta: float, power := 1.0) -> void:
	var local := to_local(point)
	# Positive steering turns left; with -Z forward, left is -X.
	var desired := atan2(-local.x, -local.z)
	steering = move_toward(steering, clampf(desired, -max_steer, max_steer), steer_rate * delta)

	var speed := get_speed()
	if speed < target_speed:
		engine_force = DRIVE_SIGN * max_engine_force * power * clampf((target_speed - speed) / 2.0, 0.25, 1.0)
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


func is_grounded() -> bool:
	for wheel in wheels:
		if wheel.is_in_contact():
			return true
	return false


func remove_from_play() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func set_ai_active(active: bool) -> void:
	_parked = not active
	for component in ai_components:
		if active:
			component.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			component.process_mode = Node.PROCESS_MODE_DISABLED

	if not active:
		engine_force = 0.0
		brake = max_brake


func _build_wheels() -> void:
	var front := _add_wheel(FRONT_WHEEL_POSITION)
	front.use_as_steering = true
	var back := _add_wheel(BACK_WHEEL_POSITION)
	back.use_as_traction = true


func _add_wheel(wheel_position: Vector3) -> VehicleWheel3D:
	var wheel := VehicleWheel3D.new()
	wheel.position = wheel_position
	wheel.wheel_radius = wheel_radius
	wheel.wheel_rest_length = suspension_rest_length
	wheel.wheel_friction_slip = tyre_grip
	wheel.suspension_travel = suspension_travel
	wheel.suspension_stiffness = suspension_stiffness
	wheel.damping_compression = damping_compression
	wheel.damping_relaxation = damping_relaxation
	add_child(wheel)
	wheels.append(wheel)
	return wheel


## Godot's tyre side friction only removes part of the sideways speed each
## frame, so parked bikes on a banked grid slowly creep. Remove it outright.
## Done on the physics state, not linear_velocity: the property is read before
## the wheels' brake impulses, so writing it back would undo the brake.
func _stop_sideways_creep(state: PhysicsDirectBodyState3D) -> void:
	var sideways := state.transform.basis.x
	var sideways_speed := state.linear_velocity.dot(sideways)
	state.linear_velocity -= sideways * sideways_speed
