class_name LapIndicator extends Label

@export var camera: RaceCamera

func _process(_delta: float) -> void:
	var target = camera.current_target() as Car
	var has_target := target != null
	visible = has_target
	if has_target:
		var progress := TrackProgress.find_on(target)
		var lap_count := progress.track.lap_count
		var lap := progress.lap
		self.text = "Following {name}: Lap {lap}/{total}".format({
			"name": target.racer.display_name,
			"lap": mini(lap, lap_count),
			"total": lap_count
		})
