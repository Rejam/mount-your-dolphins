class_name Boost extends Node
## Puts the car on rails down the middle of the road for a few seconds,
## much faster than normal. Cars in the way get shoved aside.

signal boosts_left_changed(boosts_left: int)
signal boost_started
signal boost_ended

## Seconds to get from the car's current speed to boost speed.
const RAMP_UP_TIME := 0.3
## Seconds to slide from where the car was into the middle of the road.
const CENTRE_TIME := 0.3

@export var car: Car
@export var progress: TrackProgress
@export var driver: AIDriver

var boosts_per_race: int
var duration: float
var speed_multiplier: float
var boosts_left: int
var is_boosting := false

var _time_boosting := 0.0
## Boost's own distance along the track; it moves the car, not physics.
var _distance := 0.0
var _start_speed := 0.0
## Car's position relative to the road centre when the boost started.
var _start_offset := Vector3.ZERO


func _ready() -> void:
	boosts_per_race = car.boosts_per_race
	duration = car.boost_duration
	speed_multiplier = car.boost_speed_multiplier
	boosts_left = boosts_per_race
	progress.finished.connect(_on_finished)


func _physics_process(delta: float) -> void:
	if not is_boosting:
		return
	_time_boosting += delta
	var speed := _current_speed()
	_distance += speed * delta
	car.global_transform = _rail_transform()
	if _time_boosting >= duration:
		_end(speed)


## Starts a boost if one is left and the car is racing. Returns whether it started.
func activate() -> bool:
	var can_boost := boosts_left > 0 and not is_boosting and can_process()
	if not can_boost:
		return false

	boosts_left -= 1
	is_boosting = true
	boosts_left_changed.emit(boosts_left)
	boost_started.emit()
	_time_boosting = 0.0
	_distance = progress.distance_from_start
	_start_speed = maxf(car.get_speed(), 0.0)

	# Where the car sits in the road's own space: x = sideways, y = height
	var road := progress.track.sample_transform(_distance)
	_start_offset = road.affine_inverse() * car.global_position

	# Kinematic: physics stops moving the car, but it still pushes others
	car.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	car.freeze = true
	return true


static func find_on(parent: Node) -> Boost:
	for child in parent.get_children():
		if child is Boost:
			return child
	return null


## Quick ramp from the car's speed up to boost speed, then holds.
func _current_speed() -> float:
	var boost_speed := driver.top_speed * speed_multiplier
	var ramp := minf(_time_boosting / RAMP_UP_TIME, 1.0)
	return lerpf(_start_speed, boost_speed, ramp)


## Road centre at the boost's distance, eased in from where the car started.
func _rail_transform() -> Transform3D:
	var road := progress.track.sample_transform(_distance)
	var centring := minf(_time_boosting / CENTRE_TIME, 1.0)
	var sideways := lerpf(_start_offset.x, 0.0, centring)
	# Keep the car's own ride height so the wheels stay on the road
	var height := _start_offset.y
	return road.translated_local(Vector3(sideways, height, 0.0))


func _end(speed: float) -> void:
	is_boosting = false
	car.freeze = false
	boost_ended.emit()
	# Carry on at boost speed rather than stopping dead
	var forward := -car.global_basis.z
	car.linear_velocity = forward * speed


## Finishing stops all processing, so a boost would never reach _end() by itself.
func _on_finished(_car: Car) -> void:
	if is_boosting:
		_end(_current_speed())
