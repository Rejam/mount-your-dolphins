class_name CountdownTimer extends Node

signal count(count: int)
signal ended

@export var start_from: int

var _time_left: float
var _time_left_in_seconds: int


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_time_left -= delta
	var time_left_in_seconds = ceili(_time_left)

	if time_left_in_seconds <= 0:
		stop()
		ended.emit()
		return
	if time_left_in_seconds < _time_left_in_seconds:
		count.emit(time_left_in_seconds)
		_time_left_in_seconds = time_left_in_seconds


func start() -> void:
	_time_left = float(start_from)
	_time_left_in_seconds = start_from
	set_physics_process(true)
	count.emit(start_from)


func stop() -> void:
	set_physics_process(false)


func is_active() -> bool:
	return is_physics_processing()
