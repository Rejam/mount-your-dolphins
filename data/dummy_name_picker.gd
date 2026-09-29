class_name DummyNamePicker extends RefCounted

var _unused: Array[String] = []
var _used: Array[String] = []
var loop := 0

static func create(name_list: DummyNameList) -> DummyNamePicker:
	var picker := DummyNamePicker.new()
	if name_list == null:
		push_error("DummyNamePicker: name_list not provided")
		picker._unused = []
		return picker
	var list: Array[String] = []
	list.assign(name_list.names)
	list.shuffle()
	picker._unused = list
	return picker


func next_name() -> String:
	if _unused.is_empty() and _used.is_empty():
		push_error("DummyNamePicker: No names available")
		return "no_dummy_names_available"

	# reset lists and increment loop
	if _unused.is_empty():
		loop += 1
		_unused.assign(_used)
		_used.clear()
	
	var name = _unused.pop_front()
	_used.append(name)
	if loop > 0:
		return "{name}_{loop}".format({ "name": name, "loop": loop })
		
	return  "{name}".format({ "name": name })
