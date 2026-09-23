class_name CatchUp extends Node
## Rubberband: the further this car is behind the leader, the more it's boosted.

@export var progress: TrackProgress
## Extra power and top speed at full catch-up, e.g. 0.2 = 20%.
@export_range(0.0, 0.5, 0.05) var max_boost := 0.2
## Metres behind the leader at which the full boost applies.
@export var full_boost_gap := 40.0

## 0 for the leader, rising to max_boost at full_boost_gap behind.
var boost := 0.0


func _physics_process(_delta: float) -> void:
	var gap := _leader_distance() - progress.total_distance
	boost = max_boost * clampf(gap / full_boost_gap, 0.0, 1.0)


func _leader_distance() -> float:
	var leader := -INF
	for other: TrackProgress in get_tree().get_nodes_in_group(TrackProgress.GROUP):
		leader = maxf(leader, other.total_distance)
	return leader
