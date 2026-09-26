class_name RaceTrack extends Node3D
## Track data. Route runs down the middle of the road.

@export var track_width := 4.0
@export var lap_count := 3
## Marks the start/finish line. Slide its Progress along the Route to move
## the start. All distances (grid, laps, steering, resets) count from here.
## If left empty, uses the Route's first point.
@export var start_line: PathFollow3D
## Distance between grid rows, in metres.
@export var grid_spacing := 2.5
@export var reversed := false

@onready var route: Path3D = $Route
var length := 0.0
## Where the start line sits on the Route curve, in metres.
var start_distance_along_route := 0.0

const GROUP := &"race_track"

func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	length = route.curve.get_baked_length()
	if start_line:
		start_distance_along_route = wrapf(start_line.progress, 0.0, length)


## Metres past the start line, 0 to track length
func get_lap_distance(world_pos: Vector3) -> float:
	# Curve points are relative to the Route node so must convert world to local
	var pos_on_route := route.to_local(world_pos)
	# Metres along the Route to the spot nearest this position
	var distance_along_route := route.curve.get_closest_offset(pos_on_route)
	# Account for the race's start position not being at the start of the curve
	var from_start := distance_along_route - start_distance_along_route
	# Invert if track is reversed
	if reversed:
		from_start = -from_start
	# Keep within one lap, e.g. -5 becomes length - 5
	return wrapf(from_start, 0.0, length)


## Converts a distance from the start line to a position on the Route curve.
func _distance_along_route(distance_from_start: float) -> float:
	var along_route := distance_from_start
	if reversed:
		along_route = -distance_from_start
	var distance_along_route := start_distance_along_route + along_route
	return wrapf(distance_along_route, 0.0, length)


func sample_position(distance_from_start: float) -> Vector3:
	var distance_along_route := _distance_along_route(distance_from_start)
	var local_pos := route.curve.sample_baked(distance_along_route, true)
	return route.to_global(local_pos)


## Direction of travel, from two points half a metre either side.
func sample_tangent(distance_from_start: float) -> Vector3:
	var behind := sample_position(distance_from_start - 0.5)
	var ahead := sample_position(distance_from_start + 0.5)
	return (ahead - behind).normalized()


func sample_up(distance_from_start: float) -> Vector3:
	var distance_along_route := _distance_along_route(distance_from_start)
	var local_up := route.curve.sample_baked_up_vector(distance_along_route, true)
	return route.global_basis * local_up


## The road at a distance along the track: the centre of the road,
## facing along it, tilted with any banking.
func sample_transform(distance_from_start: float) -> Transform3D:
	var pos := sample_position(distance_from_start)
	var forward := sample_tangent(distance_from_start)
	var up := sample_up(distance_from_start)
	var facing := Basis.looking_at(forward, up)
	return Transform3D(facing, pos)


## Where a car starts the race: rows of two behind the start line.
func get_grid_transform(grid_slot: int) -> Transform3D:
	var row_distance := -(floori(grid_slot / 2.0) + 1) * grid_spacing
	var side := -1 if grid_slot % 2 == 0 else 1
	var lift_above_road := 0.3
	var slot := Vector3(side, lift_above_road, 0.0)
	return sample_transform(row_distance).translated_local(slot)


## Signed metres from one lap position to another, taking the short way
## round the loop. From 99 to 1 is +2, not -98
func lap_distance_between(from: float, to: float) -> float:
	return wrapf(to - from, -length * 0.5, length * 0.5)
