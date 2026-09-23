class_name AIDriver extends Node
## Drives the car round the track: aims at a point ahead on the road and slows down for bends.

@export var car: Car
@export var progress: TrackProgress
@export var mood: AIDriverMood
@export var catch_up: CatchUp

@export_range(5.0, 20.0, 1) var top_speed := 12.0
@export_range(1.0, 15.0, 1) var corner_speed := 6.0
## Metres ahead to aim, plus extra per m/s of speed.
@export_range(1.0, 10.0, 1) var lookahead_base := 2.5
@export_range(0.0, 1.0, 0.01) var lookahead_per_speed := 0.35
## How far ahead to look for bends when choosing a speed.
@export_range(5.0, 20.0, 1) var corner_scan := 10.0
## Metres kept clear of the road edge.
@export var edge_margin := 0.5

func _physics_process(delta: float) -> void:
	var distance := progress.total_distance
	car.drive_toward(_aim_point(distance), _target_speed(distance), delta, 1.0 + _boost())


## Where to steer: a point ahead on the road, in the driver's chosen lane.
func _aim_point(at_distance: float) -> Vector3:
	var speed := maxf(car.get_speed(), 0.0)
	var lookahead := lookahead_base + speed * lookahead_per_speed
	var track := progress.track
	var road := track.sample_transform(at_distance + lookahead)
	var half_width := track.track_width * 0.5 - edge_margin
	return road.origin + road.basis.x * _lane() * half_width


## How fast to go: slower into bends, adjusted by the driver's mood.
func _target_speed(at_distance: float) -> float:
	var straight_speed := top_speed * (1.0 + _boost())
	var road_speed := lerpf(straight_speed, corner_speed, _bend_amount(at_distance))
	return road_speed * _speed_factor()


## 0 on a straight .. 1 for a right-angle bend within corner_scan metres.
func _bend_amount(at_distance: float) -> float:
	var track := progress.track
	var here := track.sample_tangent(at_distance)
	var ahead := track.sample_tangent(at_distance + corner_scan)
	return clampf(here.angle_to(ahead) / (PI * 0.5), 0.0, 1.0)

func _boost() -> float:
	return catch_up.boost if catch_up else 0.0

func _lane() -> float:
	return mood.lane if mood else 0.0

func _speed_factor() -> float:
	return mood.speed_factor if mood else 1.0
