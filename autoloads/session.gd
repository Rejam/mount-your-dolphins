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


## The next track in the shuffled order, or null if none were added.
## Race reports a missing track itself.
func next_track() -> PackedScene:
	if _shuffled_tracks.is_empty():
		return null
	var track = _shuffled_tracks[_current_track_index]
	_current_track_index += 1
	return track
