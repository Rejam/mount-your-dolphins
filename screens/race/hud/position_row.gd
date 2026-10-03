class_name PositionRow extends PanelContainer

const POSITION_ROW_UID := "uid://dw3omxxjpgxsy"
const FIRE_ICON := preload("uid://b64if2cnan822")
const SHAKE_DISTANCE := 1.0
const SHAKE_SPEED := 40.0

signal clicked(car: Car)

@onready var position_label: Label = %PositionLabel
@onready var name_label: Label = %NameLabel
@onready var click_area: Button = %ClickArea
@onready var boost_icons: HBoxContainer = %BoostIcons
@onready var boosting_indicator: PanelContainer = %BoostingIndicator

## The car this row is showing.
var car: Car

static func create() -> PositionRow:
	var row = load(POSITION_ROW_UID).instantiate() as PositionRow
	return row


func _ready() -> void:
	click_area.pressed.connect(_handle_row_pressed)
	show_is_boosting(false)


func _process(_delta: float) -> void:
	# Only shake while the boosting indicator is showing
	if boosting_indicator.visible:
		var time := Time.get_ticks_msec() / 1000.0 * SHAKE_SPEED
		# Two waves at unrelated speeds, so the motion doesn't repeat visibly
		var shake := sin(time) + sin(time * 1.7)
		# Sum of two waves, so halve it to stay within SHAKE_DISTANCE.
		boosting_indicator.position.x = shake * 0.5 * SHAKE_DISTANCE
		boosting_indicator.position.y = shake * -0.5 * SHAKE_DISTANCE


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
		icon.texture = FIRE_ICON
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		boost_icons.add_child(icon)


func show_is_boosting(is_boosting: bool) -> void:
	boosting_indicator.visible = is_boosting
		
