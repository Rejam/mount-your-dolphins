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

func _ready() -> void:
	for i in car_count:
		var car: Car = CAR_SCENE.instantiate()
		car.name = "Car%d" % (i + 1)
		cars_node.add_child(car)
		_place_on_grid(car, i)
		cars.append(car)
	race_camera.set_targets(cars)


func _place_on_grid(car: Car, grid_slot: int) -> void:
	var row_distance := -(floori(grid_slot / 2.0) + 1) * grid_spacing
	var side := -1.0 if grid_slot % 2 == 0 else 1.0
	var slot := Vector3(side, 0.3, 0.0)
	car.global_transform = track.sample_transform(row_distance).translated_local(slot)
