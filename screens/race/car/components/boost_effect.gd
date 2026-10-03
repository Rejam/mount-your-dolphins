class_name BoostEffect extends GPUParticles3D

@export var boost: Boost

func _ready() -> void:
	emitting = false
	boost.boost_started.connect(_on_boost_started)
	boost.boost_ended.connect(_on_boost_ended)


func _on_boost_started() -> void:
	emitting = true


func _on_boost_ended() -> void:
	emitting = false
