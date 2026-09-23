extends Node3D

var amplitude := 0.2
var speed := 2.0

@onready var dolphin_mesh: MeshInstance3D = $Dolphin_mesh

var offset := 0.0

func _ready():
	offset = randf_range(0.0, TAU)
	speed = randf_range(1.8, 2.2)
	
func _process(delta):
	dolphin_mesh.position.y = sin(Time.get_ticks_msec() / 1000.0 * speed) * amplitude
