class_name PositionList extends VBoxContainer

@export var standings: Standings
@export var visible_row_count := 10


func _ready() -> void:
	for i in visible_row_count:
		add_child(PositionRow.create())


func _process(_delta: float) -> void:
	var visible_placings := _get_visible(standings.order)

	for index in get_child_count():
		var row: PositionRow = get_child(index)
		var has_placing := index < visible_placings.size()
		row.visible = has_placing
		if has_placing:
			row.show_placing(visible_placings[index])


func _get_visible(placings: Array[Standings.Placing]) -> Array[Standings.Placing]:
	var racing := placings.filter(_is_racing)
	return racing.slice(0, visible_row_count)


func _is_racing(place: Standings.Placing) -> bool:
	return not place.has_finished
