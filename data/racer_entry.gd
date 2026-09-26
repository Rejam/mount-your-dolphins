class_name RacerEntry extends RefCounted

var user_id: String
var display_name: String


static func create(racer_id: String, racer_name: String) -> RacerEntry:
	var racer := RacerEntry.new()
	racer.user_id = racer_id
	racer.display_name = racer_name
	return racer

static var dummy_counter := 0

static func create_dummy(dummy_name: String) -> RacerEntry:
	dummy_counter += 1
	var dummy_id := "{0}_{1}".format([dummy_name.to_snake_case(), dummy_counter])
	return create(dummy_id, dummy_name)
