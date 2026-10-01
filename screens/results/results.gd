class_name Results extends Control

const SCENE_UID := "uid://cjywgt25sgf82"

@export var dummy_names: DummyNameList
@export var dummy_count:= 5

@onready var results_list: VFlowContainer = %ResultsList
@onready var new_race_button: Button = %NewRaceButton

var _results: Array[RaceResult]

static func create(results: Array[RaceResult]) -> Results:
	var results_scene: Results = load(SCENE_UID).instantiate()
	results_scene._results = results
	return results_scene


func _ready() -> void:
	new_race_button.pressed.connect(_on_new_race_button_pressed)
	if _results.is_empty():
		return _make_dummy_results()
	for result: RaceResult in _results:
		_add_result_to_results_list(result)


func _on_new_race_button_pressed() -> void:
	get_tree().change_scene_to_node(Registration.create())


func _add_result_to_results_list(result: RaceResult) -> void:
	var result_row := ResultRow.create()
	results_list.add_child(result_row)
	result_row.show_result(result)


func _make_dummy_results() -> void:
	var picker = DummyNamePicker.create(dummy_names)
	var prev_finish_time := 200.00
	var dnfs := dummy_count * 0.75
	for index in dummy_count:
		var result := RaceResult.new()
		result.entry = RacerEntry.create("%d" % index, picker.next_name())
		if index > dnfs:
			result.finish_time = Standings.NOT_FINISHED
			result.position = RaceResult.NO_POSITION
			result.finished = false
		else:
			result.finish_time = prev_finish_time + randf_range(0.0, 5.0)
			result.position = index + 1
			result.finished = true
			prev_finish_time = result.finish_time
		_add_result_to_results_list(result)
