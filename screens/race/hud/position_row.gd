class_name PositionRow extends PanelContainer

const POSITION_ROW_UID = "uid://dw3omxxjpgxsy"

signal clicked(car: Car)

@onready var position_label: Label = %PositionLabel
@onready var name_label: Label = %NameLabel
@onready var click_area: Button = %ClickArea

## The car this row is showing.
var car: Car


static func create() -> PositionRow:
	var row = load(POSITION_ROW_UID).instantiate() as PositionRow
	return row


func _ready() -> void:
	click_area.pressed.connect(_handle_row_pressed)


func show_placing(placing: Standings.Placing) -> void:
	car = placing.car
	name_label.text = placing.car.racer.display_name
	position_label.text = "{position}".format({ "position": placing.position })


func _handle_row_pressed() -> void:
	clicked.emit(car)
