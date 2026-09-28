class_name PositionList extends VBoxContainer

@export var standings: Standings
@export var visible_row_count := 10


func _ready() -> void:
	for i in visible_row_count:
		add_child(PositionRow.create())


func _process(_delta: float) -> void:
	var visible_placings := standings.still_racing_order.slice(0, visible_row_count)

	for index in get_child_count():
		var row: PositionRow = get_child(index)
		var has_placing := index < visible_placings.size()
		row.visible = has_placing
		if has_placing:
			row.show_placing(visible_placings[index])
