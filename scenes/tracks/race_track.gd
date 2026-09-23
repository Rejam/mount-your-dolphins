class_name RaceTrack
extends Node3D
## Track data. Route runs down the middle of the road.

@export var track_width := 4.0

@onready var route: Path3D = $Route
var length := 0.0


func _ready() -> void:
	length = route.curve.get_baked_length()


func get_progress(world_pos: Vector3) -> float:
	return route.curve.get_closest_offset(route.to_local(world_pos))


func sample_position(offset: float) -> Vector3:
	return route.to_global(route.curve.sample_baked(wrapf(offset, 0.0, length), true))


func sample_tangent(offset: float) -> Vector3:
	return (sample_position(offset + 0.5) - sample_position(offset - 0.5)).normalized()


## Road up direction, including banking.
func sample_up(offset: float) -> Vector3:
	return route.global_basis * route.curve.sample_baked_up_vector(wrapf(offset, 0.0, length), true)


## lane: -1 (left) .. 1 (right).
func sample_lane_point(offset: float, lane: float) -> Vector3:
	var right := sample_tangent(offset).cross(sample_up(offset)).normalized()
	return sample_position(offset) + right * lane * (track_width * 0.5 - 0.6)


## Facing along the track, for spawning and resetting cars.
func get_lane_transform(offset: float, lane: float) -> Transform3D:
	var facing := Basis.looking_at(sample_tangent(offset), sample_up(offset))
	return Transform3D(facing, sample_lane_point(offset, lane))
