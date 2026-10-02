class_name AIDriver extends Node
## Drives the car round the track: aims at a point ahead on the road and slows down for bends.

const TRACK_EDGE_MARGIN := 0.5
## Sideways pull the car can hold in a bend, in m/s².
## Higher = faster through corners. Placeholder: tune by watching cars.
const CORNER_GRIP := 12.0
## Metres ahead to aim, plus extra per m/s of speed.
const LOOKAHEAD_BASE := 2.5
const LOOKAHEAD_PER_SPEED := 0.35

@export var car: Car
@export var progress: TrackProgress
@export var mood: AIDriverMood

@export_range(5.0, 20.0, 1) var top_speed := 12.0


func _physics_process(delta: float) -> void:
	var distance_from_start := progress.distance_from_start
	car.drive_toward(_aim_point(distance_from_start), _target_speed(distance_from_start), delta)


## Where to steer: a point ahead on the road, in the driver's chosen lane.
func _aim_point(at_distance: float) -> Vector3:
	var speed := maxf(car.get_speed(), 0.0)
	var lookahead := LOOKAHEAD_BASE + speed * LOOKAHEAD_PER_SPEED
	var track := progress.track
	var road := track.sample_transform(at_distance + lookahead)
	var half_width := track.track_width * 0.5 - TRACK_EDGE_MARGIN
	return road.origin + road.basis.x * _lane() * half_width


## How fast to go: the speed the driver wants, capped by what the bend allows.
func _target_speed(at_distance: float) -> float:
	var wanted_speed := top_speed * _speed_factor()
	var sharpness := progress.track.get_bend_sharpness(at_distance)
	# A straight has no corner limit
	if sharpness <= 0.0:
		return wanted_speed
	# Fastest speed the car can hold through a bend this tight
	var corner_speed := sqrt(CORNER_GRIP / sharpness)
	return minf(wanted_speed, corner_speed)


func _lane() -> float:
	return mood.lane if mood else 0.0


func _speed_factor() -> float:
	return mood.speed_factor if mood else 1.0
