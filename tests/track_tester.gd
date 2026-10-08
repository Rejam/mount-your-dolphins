extends Node

@export var track: PackedScene
@export var direction: RaceTrack.TrackDirection
@export var dummy_names: DummyNameList
@export var dummy_count:= 5
@export var debug := false

func _ready() -> void:
	if not track:
		push_error("TestTrack: No track set")
		return
	var entries := _make_entries()
	var scene := Race.create(entries, track, direction)
	if debug:		
		var bend_map_debug := BendMapDebug.create()
		scene.add_child(bend_map_debug)
	
	scene.add_child(BoostDebug.new())
	get_tree().change_scene_to_node.call_deferred(scene)

func _make_entries() -> Array[RacerEntry]:
	var test_entries: Array[RacerEntry] = []
	var picker := DummyNamePicker.create(dummy_names)
	for index in dummy_count:
		var racer_name := picker.next_name()
		var dummy := RacerEntry.create_dummy(racer_name)
		test_entries.append(dummy)
	if test_entries.is_empty():
		push_warning("TestTrack: no dummy racers were created")
	return test_entries
	
