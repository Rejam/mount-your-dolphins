extends Node3D
## Runs the race: spawns cars, has them driven round the track

const CAR_SCENE = preload("uid://ch1ph3v6ippq6")

@export var car_count := 1
## Distance between grid rows, in metres.
@export var grid_spacing := 2.5

@onready var track: RaceTrack = $Track
@onready var cars_node: Node3D = %Cars
@onready var race_camera: RaceCamera = %RaceCamera

var cars: Array[Car]

const OWNER_NAMES : Array[String] = [
	"Cal Halbert", "Rejam", "BobMonkhouse", "SpeedyBrandon",
#	"I Love Chips"
]

func _ready() -> void:
	for i in car_count:
		_spawn_car(i)
	race_camera.set_targets(cars)


func _place_on_grid(car: Car, grid_slot: int) -> void:
	var row_distance := -(floori(grid_slot / 2.0) + 1) * grid_spacing
	var side := -1.0 if grid_slot % 2 == 0 else 1.0
	var slot := Vector3(side, 0.3, 0.0)
	car.global_transform = track.sample_transform(row_distance).translated_local(slot)


func _spawn_car(grid_slot: int) -> void:
	var car: Car = CAR_SCENE.instantiate()
	car.name = "Car%d" % (grid_slot + 1)
	cars_node.add_child(car)
	if grid_slot < OWNER_NAMES.size():
		car.set_owner_name(OWNER_NAMES[grid_slot])
	car.set_tint(Color.from_hsv(randf(), 0.6, 1.0))
	_place_on_grid(car, grid_slot)
	cars.append(car)
