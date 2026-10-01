class_name Dolphin extends Node3D

var amplitude := 0.2
var speed := 2.0

@onready var dolphin_mesh: MeshInstance3D = $Dolphin_mesh

var offset := 0.0

func _ready():
	offset = randf_range(0.0, TAU)
	speed = randf_range(1.8, 2.2)
	
func _process(_delta):
	dolphin_mesh.position.y = sin(Time.get_ticks_msec() / 1000.0 * speed) * amplitude


func tint(color: Color) -> void:
	var material := dolphin_mesh.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.3
	dolphin_mesh.set_surface_override_material(0, material)
