class_name Bumper extends Node
## Exaggerates collisions with other cars: pushes them apart and spins them.

@export var car: Car

var _prev_linear_velocity: Vector3


func _ready() -> void:
	car.contact_monitor = true
	car.max_contacts_reported = 4
	car.body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	_prev_linear_velocity = car.linear_velocity
	
	
func _on_body_entered(body: Node) -> void:
	var other := body as RigidBody3D
	if not other: return
	
	var strength := car.bumper_strength
	var min_kick := car.bumper_min_kick
	var max_spin := car.bumper_max_spin
	var lift := car.bumper_lift
	var away := (car.global_position - other.global_position).normalized()
	var hit := car.linear_velocity - _prev_linear_velocity
	var push := away * min_kick + hit * strength
	# Away from the road the car is on, so it's right on walls and loops too
	var car_up := car.global_basis.y
	var pop := car_up * push.length() * lift
	car.linear_velocity += push + pop
	
	var spin := randf_range(-max_spin, max_spin)
	car.angular_velocity += car.global_basis.y * spin
