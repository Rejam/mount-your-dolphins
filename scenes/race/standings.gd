class_name Standings extends Node

const NOT_FINISHED := INF

## One racer's row in the standings.
class Entry:
	var car: Car
	var progress: TrackProgress
	var finish_time:= NOT_FINISHED

var _racers: Array[Entry]
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
		var entry := Entry.new()
		entry.progress = progress_component
		entry.car = car
		
		_racers.append(entry)
		order.append(car)


func mark_finished(car: Car, race_time: float) -> void:
	for racer in _racers:
		if car == racer.car:
			if racer.finish_time == NOT_FINISHED:
				racer.finish_time = race_time
			return


## True if a should be listed above b, i.e. a is further round the race.
func _is_further_ahead(a: Entry, b: Entry) -> bool:
	# both finished: compare times
	if _has_finished(a) and _has_finished(b):
		return a.finish_time < b.finish_time
	
	if _has_finished(a):
		return true
	
	if _has_finished(b):
		return false

	var a_distance := a.progress.total_distance
	var b_distance := b.progress.total_distance
	return a_distance > b_distance


## Copies the sorted racers' cars into the public order.
func _rebuild_order() -> void:
	order.clear()
	for racer in _racers:
		order.append(racer.car)


func _has_finished(entry: Entry) -> bool:
	return entry.finish_time != NOT_FINISHED


func _print_order() -> void:
	for index in order.size():
		var placement := index + 1
		var car := order[index]
		print("{placement}: {name}".format({
			"placement": placement,
			"name": car.racer.display_name,
		}))
	print("=========================")
