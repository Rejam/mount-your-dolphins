class_name RaceAnnouncer extends Control

@export var race_director: RaceDirector

@onready var _announce_label: Label = $AnnounceLabel
@onready var _dnf_countdown_label: Label = $DnfCountdownLabel

var _flash_tween: Tween


func _ready() -> void:
	race_director.race_countdown_changed.connect(_on_race_countdown_changed)
	race_director.race_started.connect(_on_race_started)
	race_director.first_finisher.connect(_on_first_finisher)
	race_director.finish_countdown_changed.connect(_on_finish_countdown_changed)
	_reset_label(_announce_label)
	_dnf_countdown_label.visible = false


func _on_race_countdown_changed(count: int) -> void:
	_flash("%d" % count, Color.YELLOW)


func _on_race_started() -> void:
	_flash("GO!", Color.GREEN)


func _on_first_finisher(car: Car) -> void:
	_flash("%s Wins!" % car.racer.display_name, Color.GREEN, 3)
	_dnf_countdown_label.visible = true


func _on_finish_countdown_changed(count: int) -> void:
	_dnf_countdown_label.text = "Race ends in %d" % count


func _flash(text: String, color: Color, hold_duration := 0.5 ) -> void:
	if _flash_tween:
		_flash_tween.kill()
		_reset_label(_announce_label)
	
	_announce_label.scale = Vector2.ZERO
	_announce_label.visible = true
	_announce_label.text = text
	_announce_label.modulate = color

	_flash_tween = create_tween()
	_flash_tween.tween_property(_announce_label, "scale", Vector2.ONE, 0.1)
	_flash_tween.tween_interval(hold_duration)
	_flash_tween.tween_property(_announce_label, "scale", Vector2.ZERO, 0.1)

	_flash_tween.finished.connect(_reset_label.bind(_announce_label))
	

func _reset_label(label: Label) -> void:
	label.scale = Vector2.ZERO
	label.visible = false
