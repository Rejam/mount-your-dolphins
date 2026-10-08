class_name TrackAndDirection extends RefCounted

var track: PackedScene
var direction: Race.TrackDirection

static func create(scene: PackedScene, dir: Race.TrackDirection) -> TrackAndDirection:
	var track_and_dir := TrackAndDirection.new()
	track_and_dir.track = scene
	track_and_dir.direction = dir
	return track_and_dir
