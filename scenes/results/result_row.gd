class_name ResultRow extends HBoxContainer

const RESULT_ROW_UID = "uid://bfm263g5w8ee8"

@onready var position_label: Label = %PositionLabel
@onready var name_label: Label = %NameLabel
@onready var finish_time_label: Label = %FinishTimeLabel

static func create() -> ResultRow:
	var row = load(RESULT_ROW_UID).instantiate() as ResultRow
	return row

func show_result(result: RaceResult) -> void:
	name_label.text = "{name}".format({ "name": result.entry.display_name })
	if result.finished:		
		position_label.text = "{pos}".format({ "pos": result.position })
		finish_time_label.text = "{time}".format({ "time": _format_time(result.finish_time) })
	else:
		position_label.text = "-"
		finish_time_label.text = "DNF"


func _format_time(time: float) -> String:
	var minutes := floori(time / 60.0)
	var sec := floori(time) % 60
	return "%d:%02d" % [minutes, sec]
