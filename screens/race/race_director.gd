class_name RaceDirector extends Node

signal race_ended(results: Array[RaceResult])

enum Phase { NOT_STARTED, GRID_HOLD, COUNTDOWN, RACING, FINISHED }

@export var standings: Standings
@export var grid_hold_seconds := 3
@export var countdown_seconds := 3
@export var finish_time_limit_seconds := 30

@onready var grid_hold_timer: Timer = %GridHoldTimer
@onready var countdown_timer: Timer = %CountdownTimer
@onready var finish_limit_timer: Timer = %FinishLimitTimer

var current_phase := Phase.NOT_STARTED
var current_countdown: int
var _race_time := 0.0
## Seconds since GO. Read-only from outside; only RaceDirector advances it.
var race_time: float:
	get: return _race_time


func _ready() -> void:
	grid_hold_timer.wait_time = grid_hold_seconds
	grid_hold_timer.timeout.connect(_on_grid_hold_timer_timeout)
	
	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	
	finish_limit_timer.wait_time = finish_time_limit_seconds
	finish_limit_timer.timeout.connect(_finish_limit_timer_timeout)


func _physics_process(delta: float) -> void:
	if current_phase == Phase.RACING:
		_race_time += delta


func start_race(cars: Array[Car]) -> void:
	if current_phase != Phase.NOT_STARTED:
		return
	current_phase = Phase.GRID_HOLD
	grid_hold_timer.start()
	standings.start(cars)
	_set_all_cars_ai_active(false)
	_register_car_track_progress()


func _start_countdown() -> void:
	if current_phase != Phase.GRID_HOLD:
		return
	current_phase = Phase.COUNTDOWN
	current_countdown = countdown_seconds
	# Show the first number straight away, not one tick later.
	_show_countdown(current_countdown)
	countdown_timer.start()


func _go() -> void:
	if current_phase != Phase.COUNTDOWN:
		return
	current_phase = Phase.RACING
	_set_all_cars_ai_active(true)
	_race_time = 0.0
	standings.start_ranking()


func _set_all_cars_ai_active(active: bool) -> void:
	for place in standings.order:
		place.car.set_ai_active(active)


func _on_grid_hold_timer_timeout() -> void:
	_start_countdown()


func _on_countdown_timer_timeout() -> void:
	current_countdown -= 1
	var countdown_finished := current_countdown <= 0
	if countdown_finished:
		print("GO")
		_go()
		return

	_show_countdown(current_countdown)
	countdown_timer.start()


func _finish_limit_timer_timeout() -> void:
	# end even if not all finished
	print("Time Over")
	_end_race()


func _register_car_track_progress() -> void:
	for place in standings.order:
		var progress_component := TrackProgress.find_on(place.car)
		progress_component.finished.connect(_on_car_finished)


func _on_car_finished(car: Car) -> void:
	if current_phase != Phase.RACING:
		return

	standings.mark_finished(car, race_time)
	
	# no one has finished and started the countdown yet so start it
	if finish_limit_timer.is_stopped():
		print("Winner!")
		finish_limit_timer.start()

	var all_finished := standings.has_everyone_finished()
	# if everyone has finished then we can end the race immediately
	if all_finished:
		_end_race()


func _end_race() -> void:
	if current_phase != Phase.RACING:
		return

	current_phase = Phase.FINISHED
	finish_limit_timer.stop()
	print("Race finished")
	var results := _build_race_results()
	race_ended.emit(results)


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


## Placeholder until the countdown UI exists.
func _show_countdown(count: int) -> void:
	print(count)
