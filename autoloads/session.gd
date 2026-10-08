extends Node

@export var tracks: Array[PackedScene]

var _playlist: Array[TrackAndDirection]
var _current_track_index := 0:
	set(value):
		_current_track_index = wrapi(value, 0, _playlist.size())


func _ready() -> void:
	if tracks.is_empty():
		push_error("No tracks added to session")


func prepare_playlist() -> void:
	_current_track_index = 0
	_playlist.clear()
	_forward_then_reversed()


func next_track() -> TrackAndDirection:
	if _playlist.is_empty():
		return null
	var track_and_dir = _playlist[_current_track_index]
	_current_track_index += 1
	return track_and_dir


func _forward_then_reversed() -> void:
	for track in tracks:
		_playlist.append(TrackAndDirection.create(track, RaceTrack.TrackDirection.FORWARD))

	for track in tracks:
		_playlist.append(TrackAndDirection.create(track, RaceTrack.TrackDirection.BACKWARD))
