class_name Bumper extends Node
## Exaggerates collisions with other cars: pushes them apart and spins them.


@export var car: Car

## Multiplier on how hard the physics hit was. Adds on top of min_kick.
@export_range(0.0, 5.0, 0.5) var strength := 2.0
## Speed every contact pushes the cars apart with, however gentle the touch.
@export_range(0.0, 10.0, 0.5) var min_kick := 2.0
## Strongest random spin a hit can cause, in radians per second.
@export_range(0.0, 10.0, 0.5) var max_spin := 3.0
## Upward pop as a fraction of the push. Lifting the wheels off the road
## stops tyre grip soaking up the push, so hits actually move the car.
@export_range(0.0, 1.0, 0.1) var lift := 0.5

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
	
	var away := (car.global_position - other.global_position).normalized()
	var hit := car.linear_velocity - _prev_linear_velocity
	var push := away * min_kick + hit * strength
	var pop := Vector3.UP * push.length() * lift
	car.linear_velocity += push + pop
	
	var spin := randf_range(-max_spin, max_spin)
	car.angular_velocity += car.global_basis.y * spin
