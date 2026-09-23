class_name AIDriverMood extends Node
## Every few seconds, picks a new speed and lane so each car races a little differently.

## How much mood changes speed, e.g. 0.15 = up to 15% faster or slower.
@export_range(0.0, 0.5, 0.01) var strength := 0.15
## Seconds between changes of mood and lane.
@export_range(1.0, 10.0, 0.5) var change_every := 4.0
## How quickly the driver drifts to a new lane, in lanes per second.
@export_range(0.1, 2.0, 0.1) var lane_change_speed := 0.5

## Where across the road the driver wants to be: -1 left .. 1 right.
var lane := 0.0
## Multiplier on speed: below 1 when calm, above 1 when aggressive.
var speed_factor := 1.0

var _target_lane := 0.0
var _timer := Timer.new()


func _ready() -> void:
	_timer.one_shot = true
	_timer.timeout.connect(_change_mood)
	add_child(_timer)
	_timer.start(randf() * change_every)  # stagger cars


func _physics_process(delta: float) -> void:
	lane = move_toward(lane, _target_lane, lane_change_speed * delta)


func _change_mood() -> void:
	speed_factor = 1.0 + randf_range(-1.0, 1.0) * strength
	_target_lane = randf_range(-1.0, 1.0)
	_timer.start(change_every)
