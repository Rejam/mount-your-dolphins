class_name Car
extends VehicleBody3D
## A car that drives toward whatever point it's given. Knows nothing about tracks.

@export var max_engine_force := 60.0
@export var max_brake := 3.0
@export var max_steer := 0.55
@export var steer_rate := 3.0
@export var wheels : Array[VehicleWheel3D]

## The car's front is -Z, so engine force is negated to drive forward.
const DRIVE_SIGN := -1.0
## car.tscn. Loaded rather than preloaded: car.tscn uses this script, so a
## preload here would be a cyclic reference.
const SCENE_PATH := "uid://ch1ph3v6ippq6"

## Shown above the car. Set before adding the car to the tree.
var owner_name := ""

@onready var owner_label: Label3D = %OwnerLabel
@onready var model: Dolphin = $Model


## Makes a new car for a viewer. Add it to the tree, then place it.
static func create(for_owner: String) -> Car:
	var car: Car = load(SCENE_PATH).instantiate()
	car.owner_name = for_owner
	car.name = "Car_%s" % for_owner
	return car


func _ready() -> void:
	# A low centre of mass keeps the car from rolling in corners.
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.15, 0.0)
	owner_label.text = owner_name
	model.tint(Color.from_hsv(randf(), 0.6, 1.0))


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
