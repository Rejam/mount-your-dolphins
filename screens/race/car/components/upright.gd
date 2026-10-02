class_name Upright extends RayCast3D
## Stops a two-wheeled car falling sideways: twists it around its nose until
## it stands square to the road under it. No road under it (flipped, knocked
## clear) means no twist, so it can still crash.

@export var car: Car

func _physics_process(_delta: float) -> void:
	if not is_colliding():
		return
	# The car's front is -Z
	var nose := -car.global_basis.z
	var car_up := car.global_basis.y
	# Road's up seen looking along the nose: front-to-back tilt removed,
	# because the two wheels already hold that
	var road_up_across := get_collision_normal().slide(nose).normalized()
	# How far the bike leans, and how fast it's leaning, around its nose
	var lean := car_up.signed_angle_to(road_up_across, nose)
	var lean_speed := car.angular_velocity.dot(nose)
	var spin_up := nose * (lean * car.upright_strength - lean_speed * car.upright_damping)
	# Turn "spin up this fast" into the torque this body needs for it
	var body_state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	var inertia := body_state.inverse_inertia_tensor.inverse()
	car.apply_torque(inertia * spin_up)
