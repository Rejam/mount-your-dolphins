class_name TrackProgress extends Node
const GROUP := &"track_progress"

@export var car: Car

var track : RaceTrack

## Progress travelled along track. Starts negative before race start
## Continues increasing each lap
var total_distance := 0.0

## Like distance but does not go down if progresses backward
## Recovery uses it to decide whether the car is still making progress.
var best_distance := 0.0

## Metres into the current lap, 0 to track length.
var lap_distance := 0.0

## Current lap, starting at 1. Still 1 on the grid, before the start line.
var lap: int:
	get: return maxi(floori(total_distance / track.length) + 1, 1)


func _enter_tree() -> void:
	add_to_group(GROUP)
	

func _ready() -> void:
	track = get_tree().get_first_node_in_group(RaceTrack.GROUP)


func _physics_process(_delta: float) -> void:
	if car.is_grounded():
		_update_progress()


func _update_progress() -> void:
	var new_lap_distance := track.get_lap_distance(car.global_position)
	var moved := track.lap_distance_between(lap_distance, new_lap_distance)
	lap_distance = new_lap_distance
	total_distance += moved
	best_distance = maxf(best_distance, total_distance)


func reset(at_distance: float) -> void:
	total_distance = at_distance
	best_distance = at_distance
	lap_distance = wrapf(at_distance, 0.0, track.length)


static func find_on(parent: Node) -> TrackProgress:
	for child in parent.get_children():
		if child is TrackProgress:
			return child
	return null
	
