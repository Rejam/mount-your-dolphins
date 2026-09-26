class_name Standings extends Node

var _racers: Array[StandingsEntry]
var order: Array[Car]
var print_timer:= Timer.new()


func _ready() -> void:
	print_timer.wait_time = 5
	print_timer.timeout.connect(_print_order)
	add_child(print_timer)
	print_timer.start()


func _physics_process(_delta: float) -> void:
	_racers.sort_custom(_is_further_ahead)
	_rebuild_order()


func start(cars: Array[Car]) -> void:
	for car in cars:
		var progress_component := TrackProgress.find_on(car)
		if not progress_component:
			push_error("Standings: TrackProgress component not found on {car}".format({
				"car": car.racer.display_name }
			))
			continue
		
		var standing := StandingsEntry.new()
		standing.progress = progress_component
		standing.car = car
		
		_racers.append(standing)
		order.append(car)


## True if a should be listed above b, i.e. a is further round the race.
func _is_further_ahead(a: StandingsEntry, b: StandingsEntry) -> bool:
	var a_distance := a.progress.total_distance
	var b_distance := b.progress.total_distance
	return a_distance > b_distance


## Copies the sorted racers' cars into the public order.
func _rebuild_order() -> void:
	order.clear()
	for racer in _racers:
		order.append(racer.car)


func _print_order() -> void:
	for index in order.size():
		var placement := index + 1
		var car := order[index]
		print("{placement}: {name}".format({
			"placement": placement,
			"name": car.racer.display_name,
		}))
	print("=========================")
