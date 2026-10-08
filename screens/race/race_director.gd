class_name RaceDirector extends Node

signal race_countdown_changed(count: int)
signal race_started
signal first_finisher(car: Car)
signal finish_countdown_changed(count: int)
signal race_ended(results: Array[RaceResult])

enum Phase { NOT_STARTED, GRID_HOLD, COUNTDOWN, RACING, FINISHED }

@export var standings: Standings

@onready var race_countdown: CountdownTimer = %RaceCountdown
@onready var grid_hold_countdown: CountdownTimer = %GridHoldCountdown
@onready var finish_countdown: CountdownTimer = %FinishCountdown

var current_phase := Phase.NOT_STARTED
var _race_time := 0.0
## Seconds since GO. Read-only from outside; only RaceDirector advances it.
var race_time: float:
	get: return _race_time

func _ready() -> void:
	grid_hold_countdown.ended.connect(_on_grid_hold_countdown_ended)
	
	race_countdown.count.connect(_on_race_countdown_count)
	race_countdown.ended.connect(_on_race_countdown_ended)
	
	finish_countdown.count.connect(_on_finish_countdown_count)
	finish_countdown.ended.connect(_on_finish_countdown_ended)


func _physics_process(delta: float) -> void:
	if current_phase == Phase.RACING:
		_race_time += delta


func start_race(cars: Array[Car]) -> void:
	if current_phase != Phase.NOT_STARTED:
		return
	current_phase = Phase.GRID_HOLD
	grid_hold_countdown.start()
	standings.start(cars)
	_set_all_cars_ai_active(false)
	_register_car_track_progress()


func _go() -> void:
	if current_phase != Phase.COUNTDOWN:
		return
	current_phase = Phase.RACING
	_set_all_cars_ai_active(true)
	_race_time = 0.0
	standings.start_ranking()
	race_started.emit()


func _on_grid_hold_countdown_ended() -> void:
	current_phase = Phase.COUNTDOWN
	race_countdown.start()


func _on_race_countdown_count(count: int) -> void:
	race_countdown_changed.emit(count)


func _on_race_countdown_ended() -> void:
	_go()


func _on_finish_countdown_count(count: int) -> void:
	finish_countdown_changed.emit(count)


func _on_finish_countdown_ended() -> void:
	_end_race()


func _on_car_finished(car: Car) -> void:
	if current_phase != Phase.RACING:
		return

	standings.mark_finished(car, race_time)
	
	# no one has finished and started the countdown yet so start it
	if not finish_countdown.is_active():
		first_finisher.emit(car)
		finish_countdown.start()

	var all_finished := standings.has_everyone_finished()
	# if everyone has finished then we can end the race immediately
	if all_finished:
		_end_race()


func _end_race() -> void:
	if current_phase != Phase.RACING:
		return

	current_phase = Phase.FINISHED
	finish_countdown.stop()
	var results := _build_race_results()
	race_ended.emit(results)


func _set_all_cars_ai_active(active: bool) -> void:
	for place in standings.order:
		place.car.set_ai_active(active)


func _register_car_track_progress() -> void:
	for place in standings.order:
		var progress_component := TrackProgress.find_on(place.car)
		progress_component.finished.connect(_on_car_finished)


func _build_race_results() -> Array[RaceResult]:
	var results : Array[RaceResult] = []

	for place in standings.order:
		var result := RaceResult.new()
		
		result.entry = place.car.racer
		result.finish_time = place.finish_time
		result.finished = place.has_finished
		if place.has_finished:
			result.position = place.position
		else:
			result.position = RaceResult.NO_POSITION
		
		results.append(result)

	return results
