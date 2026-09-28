class_name PositionRow extends HBoxContainer

@onready var position_label: Label = %PositionLabel
@onready var name_label: Label = %NameLabel

const POSITION_ROW_UID = "uid://dw3omxxjpgxsy"

static func create() -> PositionRow:
	var row = load(POSITION_ROW_UID).instantiate() as PositionRow
	return row

func show_placing(placing: Standings.Placing) -> void:
	name_label.text = placing.car.racer.display_name
	position_label.text = "{position}".format({ "position": placing.position })
