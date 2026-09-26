extends Node3D
## Runs the race: spawns cars, has them driven round the track

@export var test_racer_names: PackedStringArray

@onready var track: RaceTrack = $Track
@onready var cars_node: Node3D = %Cars
@onready var race_camera: RaceCamera = %RaceCamera

var cars: Array[Car]


func _ready() -> void:
	for index in test_racer_names.size():
		var test_racer_name := test_racer_names[index]
		var dummy_racer = RacerEntry.create_dummy(test_racer_name)
		_spawn_car(index, dummy_racer)
	race_camera.set_targets(cars)


func _spawn_car(grid_slot: int, racer: RacerEntry) -> void:
	var car := Car.create(racer)
	cars.append(car)
	cars_node.add_child(car)
	car.global_transform = track.get_grid_transform(grid_slot)
