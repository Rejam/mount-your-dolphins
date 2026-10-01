class_name PositionTag extends Label3D

@export var car: Car

var standings: Standings

func _ready() -> void:
	standings = get_tree().get_first_node_in_group(Standings.GROUP)
	

func _process(_delta: float) -> void:
	var pos := standings.get_position(car)
	self.text = "{pos}".format({ "pos": pos})
