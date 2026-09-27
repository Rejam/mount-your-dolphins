class_name Standings extends Node

const NOT_FINISHED := INF

## One racer's row in the standings.
class Placing:
	var car: Car
	var progress: TrackProgress
	var finish_time:= NOT_FINISHED
	## 1 = leading. Finishers on the same time share a position (1, 1, 3).
	var position := 0
	var has_finished: bool:
		get: return finish_time != NOT_FINISHED

## Racers from leader to last. Starts in grid order; re-ranked every
## physics frame once start_ranking() is called.
var order: Array[Placing]


func _ready() -> void:
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	_rank()


func start(cars: Array[Car]) -> void:
	for car in cars:
		var placing := Placing.new()
		placing.car = car
		placing.progress = TrackProgress.find_on(car)
		order.append(placing)
	# Grid order gives positions 1..n straight away.
	_assign_positions()
	

func start_ranking() -> void:
	set_physics_process(true)


func mark_finished(car: Car, race_time: float) -> void:
	for placing in order:
		if placing.car != car:
			continue
		if not placing.has_finished:
			placing.finish_time = race_time
			# Rank now so results built this frame include this finish.
			_rank()
		return


## True if a should be listed above b, i.e. a is further round the race.
func _is_further_ahead(a: Placing, b: Placing) -> bool:
	# both finished: compare times
	if a.has_finished and b.has_finished:
		return a.finish_time < b.finish_time
	
	if a.has_finished:
		return true
	
	if b.has_finished:
		return false

	var a_distance := a.progress.distance_from_start
	var b_distance := b.progress.distance_from_start
	return a_distance > b_distance


func has_everyone_finished() -> bool:
	for placing in order:
		if not placing.has_finished:
			return false
	return true


func _rank() -> void:
	order.sort_custom(_is_further_ahead)
	_assign_positions()


## Positions follow the order, except finishers on the same time share one.
func _assign_positions() -> void:
	var previous: Placing = null
	for index in order.size():
		var placing := order[index]
		placing.position = index + 1
		if previous and _is_tied(placing, previous):
			placing.position = previous.position
		previous = placing


## Only finishers can tie. Unfinished racers both hold NOT_FINISHED,
## which would otherwise compare as equal.
func _is_tied(a: Placing, b: Placing) -> bool:
	if not a.has_finished:
		return false
	return a.finish_time == b.finish_time
