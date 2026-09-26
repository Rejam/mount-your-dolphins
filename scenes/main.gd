class_name Main extends Node3D
## Runs the race: spawns cars, has them driven round the track

const MAIN_SCENE_UID := "uid://bcjuf0jo60p2d"

@export var test_racer_names: PackedStringArray

var cars: Array[Car]
var track: RaceTrack

var _entries: Array[RacerEntry]
var _track_scene: PackedScene

@onready var cars_node: Node3D = %Cars
@onready var race_camera: RaceCamera = %RaceCamera
@onready var race_director: RaceDirector = %RaceDirector


func _ready() -> void:
	var was_run_standalone := _track_scene == null
	if was_run_standalone:
		# create() wasn't used, so the scene is being run on its own (F6):
		# fall back to test racers and the next track from Session.
		_track_scene = Session.next_track()
		_entries = _make_test_racers()
		
	var track_ready := _spawn_track(_track_scene)
	if not track_ready:
		return
		
	for grid_slot in _entries.size():
		_spawn_car(grid_slot, _entries[grid_slot])
	race_camera.set_targets(cars)
	race_director.start_race(cars)


static func create(entries: Array[RacerEntry], track_scene: PackedScene) -> Main:
	var main: Main = load(MAIN_SCENE_UID).instantiate()
	main._entries = entries
	main._track_scene = track_scene
	return main



## Builds the track with a random direction. Returns false if no scene or the scene isn't a RaceTrack.
func _spawn_track(track_scene: PackedScene) -> bool:
	if not track_scene:
		push_error("Main: no track scene provided to spawn")
		return false

	var track_root := track_scene.instantiate()
	track = track_root as RaceTrack
	if not track:
		push_error("Main: the track scene's root is not a RaceTrack")
		track_root.free()
		return false

	# Direction must be set before the track enters the tree.
	var runs_reversed := randi_range(0, 1) == 1
	track.reversed = runs_reversed
	add_child(track)
	return true


func _spawn_car(grid_slot: int, racer: RacerEntry) -> void:
	var car := Car.create(racer)
	cars.append(car)
	cars_node.add_child(car)
	car.global_transform = track.get_grid_transform(grid_slot)


func _make_test_racers() -> Array[RacerEntry]:
	var test_racers: Array[RacerEntry] = []
	for test_racer in test_racer_names:
		var dummy_racer = RacerEntry.create_dummy(test_racer)
		test_racers.append(dummy_racer)
	if test_racers.is_empty():
		push_warning("Main: run on its own with no test_racer_names, so no cars will spawn")
	return test_racers
	
