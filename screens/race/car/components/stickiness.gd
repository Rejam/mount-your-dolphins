class_name Stickiness extends RayCast3D
## Pulls the car toward the road under it, even when the wheels lift,
## so it holds crests and loops. No road under it (flipped, rolled,
## knocked clear) means no pull, so the car can come off.

@export var car: Car


func _physics_process(_delta: float) -> void:
	if not is_colliding():
		return
	# The road surface's "up" where the ray hits it
	var road_up := get_collision_normal()
	var pull_into_road := -road_up * car.mass * car.stickiness
	car.apply_central_force(pull_into_road)
