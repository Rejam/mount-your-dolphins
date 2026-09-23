class_name RaceTrack extends Node3D
## Track data. Route runs down the middle of the road.

@export var track_width := 4.0

@onready var route: Path3D = $Route
var length := 0.0

const GROUP := &"race_track"


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	length = route.curve.get_baked_length()


func get_lap_distance(world_pos: Vector3) -> float:
	return route.curve.get_closest_offset(route.to_local(world_pos))


func sample_position(at_distance: float) -> Vector3:
	return route.to_global(route.curve.sample_baked(wrapf(at_distance, 0.0, length), true))


func sample_tangent(at_distance: float) -> Vector3:
	return (sample_position(at_distance + 0.5) - sample_position(at_distance - 0.5)).normalized()


## Road up direction, including banking.
func sample_up(at_distance: float) -> Vector3:
	return route.global_basis * route.curve.sample_baked_up_vector(wrapf(at_distance, 0.0, length), true)


## The road at a distance along the track: the centre of the road,
## facing along it, tilted with any banking.
func sample_transform(at_distance: float) -> Transform3D:
	var pos := sample_position(at_distance)
	var forward := sample_tangent(at_distance)
	var up := sample_up(at_distance)
	var facing := Basis.looking_at(forward, up)
	return Transform3D(facing, pos)


## Signed metres from one lap position to another, taking the short way
## round the loop. From 519.9 to 0.1 is +0.2, not -519.8.
func lap_distance_between(from: float, to: float) -> float:
	return wrapf(to - from, -length * 0.5, length * 0.5)
