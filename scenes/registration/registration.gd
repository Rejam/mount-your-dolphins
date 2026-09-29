class_name Registration extends Control

const REGISTRATION_SCENE_UID = "uid://c7de3ak43n20s"

@export var dummy_names: DummyNameList
@export_range(1, 5) var min_racers := 2
@export_range(1, 200) var max_racers := 30

@onready var entrant_list: VFlowContainer = %EntrantList
@onready var add_dummy_button: Button = %AddDummyButton
@onready var race_button: Button = %RaceButton
@onready var count_label: Label = %CountLabel

var _entries: Array[RacerEntry]
var _name_picker: DummyNamePicker

static func create() -> Registration:
	var reg_scene: Registration = load(REGISTRATION_SCENE_UID).instantiate()
	return reg_scene


func _ready() -> void:
	_name_picker = DummyNamePicker.create(dummy_names)
	add_dummy_button.pressed.connect(_on_add_dummy_button_pressed)
	race_button.pressed.connect(_on_race_button_pressed)
	Twitch.mount_requested.connect(_on_mount_requested)
	_refresh()


func _add_entry(entry: RacerEntry) -> void:
	if _entries.size() >= max_racers:
		return
	_entries.append(entry)
	_add_entry_to_entrant_list(entry.display_name)
	_refresh()


func _on_add_dummy_button_pressed() -> void:
	var entry := RacerEntry.create_dummy(_name_picker.next_name())
	_add_entry(entry)


func _on_race_button_pressed() -> void:
	race_button.disabled = true
	_entries.shuffle()
	var track := Session.next_track()
	var race_scene := Main.create(_entries, track)
	get_tree().change_scene_to_node(race_scene)


func _refresh() -> void:
	var entry_count := _entries.size()
	_set_entrant_count_label(entry_count)
	race_button.disabled = entry_count < min_racers
	add_dummy_button.disabled = entry_count >= max_racers


func _add_entry_to_entrant_list(entrant_name: String) -> void:
	var label := Label.new()
	label.text = entrant_name
	label.custom_minimum_size.y = 26
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entrant_list.add_child(label)


func _set_entrant_count_label(count: int) -> void:
	count_label.text = "{count}/{max}".format({ "count": count, "max": max_racers })


func _on_mount_requested(entry: RacerEntry) -> void:
	for racer in _entries:
		if racer.user_id == entry.user_id:
			return
	_add_entry(entry)
