class_name Recovery extends Node
## Puts the car back on the track if it stops making progress.

@export var car: Car
@export var progress: TrackProgress

## Seconds without progress before a car is reset.
@export var stuck_time := 4.0
## Metres a car must gain within stuck_time to count as progressing.
@export var min_progress := 1.0
## How far past its best point a car is placed when reset.
@export var reset_ahead := 1.0

var _checkpoint := -INF
var _stuck_timer := 0.0


func _physics_process(delta: float) -> void:
	if _is_stuck(delta):
		_recover()


## True once best hasn't advanced by min_progress for stuck_time seconds.
func _is_stuck(delta: float) -> bool:
	var has_made_progress := progress.best_distance >= _checkpoint + min_progress
	if has_made_progress:
		_checkpoint = progress.best_distance
		_stuck_timer = 0.0
		return false
	_stuck_timer += delta
	return _stuck_timer >= stuck_time


## Put the car back on the track just past the furthest point it reached.
func _recover() -> void:
	var track := progress.track
	var at_distance := progress.best_distance + reset_ahead
	var recovery_point := track.sample_transform(at_distance)
	recovery_point = recovery_point.translated_local(Vector3.UP * 0.3)
	car.reset_to(recovery_point)
	progress.reset(at_distance)
	_checkpoint = at_distance
	_stuck_timer = 0.0
