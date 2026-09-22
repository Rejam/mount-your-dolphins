extends CharacterBody3D

## Placeholder car controller for prototyping.
## No player input at all — the car just drives forward at a
## constant speed. This is step 1 of the build: get movement and
## collision feeling right before AI waypoint-following (step 2)
## replaces the straight-line driving.

@export var speed: float = 8.0
@export var gravity: float = 20.0

func _physics_process(delta: float) -> void:
	# Drive forward continuously (forward = -Z in local space, shown
	# by the yellow "nose" marker on the mesh).
	var forward: Vector3 = -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	# Simple gravity so the car settles onto the track surface.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
