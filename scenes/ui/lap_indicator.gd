class_name LapIndicator extends Label

@export var camera: RaceCamera

func _process(_delta: float) -> void:
	var target = camera.current_target() as Car
	if target:
		var progress := TrackProgress.find_on(target)
		var lap_count := progress.track.lap_count
		var lap := progress.lap
		self.text = "Following {name}: Lap {lap}/{total}".format({
			"name": target.racer.display_name,
			"lap": mini(progress.lap, lap_count),
			"total": progress.track.lap_count
		})
	
