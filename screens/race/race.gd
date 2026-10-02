class_name Race extends Node3D
## Runs the race: spawns cars, has them driven round the track

const SCENE_UID := "uid://bcjuf0jo60p2d"
enum TrackDirection { RANDOM, FORWARD, BACKWARD }

var cars: Array[Car]
var track: RaceTrack

var _entries: Array[RacerEntry]
var _track_scene: PackedScene
var _track_direction: TrackDirection

@onready var cars_node: Node3D = %Cars
@onready var race_camera: RaceCamera = %RaceCamera
@onready var race_director: RaceDirector = %RaceDirector
@onready var position_list: PositionList = %PositionList


static func create(entries: Array[RacerEntry], track_scene: PackedScene, direction:= TrackDirection.RANDOM) -> Race:
	var scene: Race = load(SCENE_UID).instantiate()
	scene._entries = entries
	scene._track_scene = track_scene
	scene._track_direction = direction
	return scene


func _ready() -> void:
	var track_ready := _spawn_track(_track_scene)
	if not track_ready:
		return
		
	for grid_slot in _entries.size():
		_spawn_car(grid_slot, _entries[grid_slot])
	race_camera.set_targets(cars)
	race_director.start_race(cars)
	race_director.race_ended.connect(_on_race_ended)
	position_list.car_clicked.connect(race_camera.select_by_user)
	Twitch.boost_requested.connect(_on_boost_requested)


## Builds the track. Returns false if no scene or the scene isn't a RaceTrack.
func _spawn_track(track_scene: PackedScene) -> bool:
	if not track_scene:
		push_error("Race: no track scene provided to spawn. Use test track scene")
		return false

	var track_root := track_scene.instantiate()
	track = track_root as RaceTrack
	if not track:
		push_error("Race: the track scene's root is not a RaceTrack")
		track_root.free()
		return false

	# Direction must be set before the track enters the tree.
	var is_track_reverse: bool
	match _track_direction:
		TrackDirection.RANDOM:
			is_track_reverse = randi_range(0, 1) == 1
		TrackDirection.BACKWARD:
			is_track_reverse = true
		TrackDirection.FORWARD:
			is_track_reverse = false
	
	track.reversed = is_track_reverse
	add_child(track)
	return true


func _spawn_car(grid_slot: int, racer: RacerEntry) -> void:
	var car := Car.create(racer)
	var can_race := _can_race(car)
	if not can_race: 
		car.free()
		return
	cars.append(car)
	cars_node.add_child(car)
	car.global_transform = track.get_grid_transform(grid_slot)


func _can_race(car: Car) -> bool:
	var progress_component := TrackProgress.find_on(car)
	if not progress_component:
		push_error("Race: TrackProgress component not found on {car}".format({
			"car": car.racer.display_name }
		))
		return false
	return true


func _on_race_ended(results: Array[RaceResult]) -> void:
	get_tree().change_scene_to_node(Results.create(results))


func _on_boost_requested(player: TwitchPlayer) -> void:
	var car := _find_car(player.user_id)
	if not car:
		return
	var boost := Boost.find_on(car)
	if boost:
		boost.activate()

func _find_car(user_id: String) -> Car:
	for car in cars:
		if car.racer.user_id == user_id:
			return car
	return null
