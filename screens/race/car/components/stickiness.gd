class_name Stickiness extends Node
## Pulls the car toward the surface under its wheels, so it can hold steep slopes.

@export_range(0.0, 30.0, 1) var strength := 15.0
@export var car: Car

func _physics_process(_delta: float) -> void:
	var touching := 0
	for wheel in car.wheels:
		if wheel.is_in_contact():
			touching += 1
	if touching > 0:
		var grip := float(touching) / car.wheels.size()
		var mass := car.mass
		var global_basis_y := car.global_basis.y
		var force := -global_basis_y * mass * strength * grip
		car.apply_central_force(force)
