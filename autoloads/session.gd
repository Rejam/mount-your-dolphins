extends Node

@export var tracks: Array[PackedScene]

var _shuffled_tracks: Array[PackedScene]
var _current_track_index := 0:
	set(value):
		_current_track_index = wrapi(value, 0, _shuffled_tracks.size())


func _ready() -> void:
	if tracks.is_empty():
		push_error("No tracks added to session")
	_shuffled_tracks = tracks.duplicate()


func shuffle_tracks() -> void:
	_current_track_index = 0
	_shuffled_tracks.shuffle()


func next_track() -> PackedScene:
	var track = _shuffled_tracks[_current_track_index]
	_current_track_index += 1
	return track
