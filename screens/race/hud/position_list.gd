class_name PositionList extends Control
## Live race order. Each car keeps the same row for the whole race, and rows
## slide to their new slot when the order changes, so a name can be followed by eye.

## How quickly rows slide to their slot. Higher = snappier.
const SLIDE_SMOOTHING := 10.0
## Vertical space between rows, in pixels.
const ROW_GAP := 2.0

signal car_clicked(car: Car)

@export var standings: Standings
@export var visible_row_count := 20

## Each car's row, created the first time that car makes the list.
var _rows: Dictionary[Car, PositionRow] = {}


func _process(delta: float) -> void:
	var visible_placings := standings.still_racing_order.slice(0, visible_row_count)
	# Frame-rate independent ease towards the target, same as RaceCamera.
	var slide_weight := 1.0 - exp(-SLIDE_SMOOTHING * delta)
	var shown_rows: Dictionary[PositionRow, bool] = {}
	var slot_top := 0.0

	for placing in visible_placings:
		var row := _get_row(placing.car)
		row.show_placing(placing)
		# Shrink to fit the text; the row scene's own size is bigger.
		row.reset_size()

		var is_entering_list := not row.visible
		if is_entering_list:
			# Appear straight in the slot rather than sliding in from an old place.
			row.position.y = slot_top
			row.visible = true
		else:
			row.position.y = lerpf(row.position.y, slot_top, slide_weight)

		shown_rows[row] = true
		slot_top += row.size.y + ROW_GAP

	# Cars that dropped out of the top rows, or finished.
	for row in _rows.values():
		if not shown_rows.has(row):
			row.visible = false


func _get_row(car: Car) -> PositionRow:
	if not _rows.has(car):
		var row := PositionRow.create()
		row.visible = false
		row.clicked.connect(car_clicked.emit)
		add_child(row)
		_rows[car] = row
		_connect_boost(car, row)
	return _rows[car]


## Starts the row at the car's current boost count and keeps it updated.
## A car without a Boost shows no icons.
func _connect_boost(car: Car, row: PositionRow) -> void:
	var boost := Boost.find_on(car)
	if not boost:
		row.show_boosts_left(0)
		return
	row.show_boosts_left(boost.boosts_left)
	boost.boosts_left_changed.connect(row.show_boosts_left)
