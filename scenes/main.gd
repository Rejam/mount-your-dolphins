extends Node3D
## Runs the race: spawns cars, has them driven round the track

@export var car_count := 1

@onready var track: RaceTrack = $Track
@onready var cars_node: Node3D = %Cars
@onready var race_camera: RaceCamera = %RaceCamera

var cars: Array[Car]

const OWNER_NAMES : Array[String] = [
	"Cal Halbert", "Rejam", "BobMonkhouse", "SpeedyBrandon", #"I Love Chips"
]

func _ready() -> void:
	for i in car_count:
		var owner_name := OWNER_NAMES[i] if i < OWNER_NAMES.size() else ""
		_spawn_car(i, owner_name)
	race_camera.set_targets(cars)


func _spawn_car(grid_slot: int, owner_name: String) -> void:
	var car := Car.create(owner_name)
	cars.append(car)
	cars_node.add_child(car)
	car.global_transform = track.get_grid_transform(grid_slot)
