class_name RaceTrack extends Node3D
## Track data. Route runs down the middle of the road.

const GROUP := &"race_track"
const BEND_FADE_PER_METRE := 0.005

@export var track_width := 4.0
@export var lap_count := 3
## Marks the start/finish line. Slide its Progress along the Route to move
## the start. All distances (grid, laps, steering, resets) count from here.
@export var start_line: PathFollow3D
## Distance between grid rows, in metres.
@export var grid_spacing := 2.5
@export var reversed := false

var lap_length : float
## Where the start line sits on the Route curve, in metres.
var start_distance_along_route := 0.0
var race_length : float:
	get: return lap_length * lap_count
# samples every 1 meter
var _bend_map: PackedFloat32Array


@onready var route: Path3D = $Route

func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	lap_length = route.curve.get_baked_length()
	if start_line:
		start_distance_along_route = wrapf(start_line.progress, 0.0, lap_length)
	_bake_bend_map()


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
	# Keep within one lap, e.g. -5 becomes lap_length - 5
	return wrapf(from_start, 0.0, lap_length)


## Warning how sharp the road is here, including the fade before bends.
## 0 on a straight; 0.1 is a 10 m radius bend.
func get_bend_warning(distance_from_start: float) -> float:
	# Distances keep counting up across laps; bring it back into one lap
	var lap_distance := wrapf(distance_from_start, 0.0, lap_length)
	var sample_index := floori(lap_distance)
	return _bend_map[sample_index]


## Converts a distance from the start line to a position on the Route curve.
func _distance_along_route(distance_from_start: float) -> float:
	var along_route := distance_from_start
	if reversed:
		along_route = -distance_from_start
	var distance_along_route := start_distance_along_route + along_route
	return wrapf(distance_along_route, 0.0, lap_length)


func _sample_position(distance_from_start: float) -> Vector3:
	var distance_along_route := _distance_along_route(distance_from_start)
	var local_pos := route.curve.sample_baked(distance_along_route, true)
	return route.to_global(local_pos)


## Direction of travel, from two points half a metre either side.
func sample_tangent(distance_from_start: float) -> Vector3:
	var behind := _sample_position(distance_from_start - 0.5)
	var ahead := _sample_position(distance_from_start + 0.5)
	return (ahead - behind).normalized()


func _sample_up(distance_from_start: float) -> Vector3:
	var distance_along_route := _distance_along_route(distance_from_start)
	var local_up := route.curve.sample_baked_up_vector(distance_along_route, true)
	return route.global_basis * local_up


## The road at a distance along the track: the centre of the road,
## facing along it, tilted with any banking.
func sample_transform(distance_from_start: float) -> Transform3D:
	var pos := _sample_position(distance_from_start)
	var forward := sample_tangent(distance_from_start)
	var up := _sample_up(distance_from_start)
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
	return wrapf(to - from, -lap_length * 0.5, lap_length * 0.5)


func _bake_bend_map() -> void:
	var sample_count := ceili(lap_length)
	_bend_map.resize(sample_count)
	
	for distance_from_start in sample_count:
		_bend_map[distance_from_start] = _curvature_at(distance_from_start)
	
	# Twice round: a bend just after the start line has to fade back
	# across the wrap into the end of the lap
	var laps_to_walk := 2
	for step in sample_count * laps_to_walk:
		var sample_index := sample_count - 1 - (step % sample_count)
		var next_index := wrapi(sample_index + 1, 0, sample_count)
		var faded_from_next := _bend_map[next_index] - BEND_FADE_PER_METRE
		_bend_map[sample_index] = maxf(_bend_map[sample_index], faded_from_next)


## How sharply the road turns across its own surface here, in radians per metre.
## Up/down changes (hills, crests, loops) are ignored.
func _curvature_at(distance_from_start: float) -> float:
	var half_step := 0.5
	# slide() needs a unit-length normal; normalise in case the Route is scaled
	var up := _sample_up(distance_from_start).normalized()
	# Road direction just behind and just ahead of this point
	var behind := sample_tangent(distance_from_start - half_step)
	var ahead := sample_tangent(distance_from_start + half_step)
	# Remove the part of each direction along the road's up,
	# leaving only the left/right turn across the surface
	var behind_across := behind.slide(up).normalized()
	var ahead_across := ahead.slide(up).normalized()
	var turn_angle := behind_across.angle_to(ahead_across)
	return turn_angle
