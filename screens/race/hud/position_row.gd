class_name PositionRow extends PanelContainer

const POSITION_ROW_UID := "uid://dw3omxxjpgxsy"
const FIRE_ICON_UID := preload("uid://b64if2cnan822")

signal clicked(car: Car)

@onready var position_label: Label = %PositionLabel
@onready var name_label: Label = %NameLabel
@onready var click_area: Button = %ClickArea
@onready var boost_icons: HBoxContainer = %BoostIcons

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


## Shows one icon per boost the car still has.
func show_boosts_left(count: int) -> void:
	for icon in boost_icons.get_children():
		icon.free()
	for index in count:
		var icon := TextureRect.new()
		icon.texture = FIRE_ICON_UID
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		boost_icons.add_child(icon)
