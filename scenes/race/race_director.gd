class_name RaceDirector extends Node

@export var standings: Standings

func start_race(cars: Array[Car]) -> void:
	standings.start(cars)
