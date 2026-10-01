class_name RaceAnnouncer extends Control
## Big on-screen race calls (3-2-1, GO, winner) and the "race ends in" line.

const COUNTDOWN_COLOR := Color("ffd23f")
const GO_COLOR := Color("3cf06e")
const WINNER_COLOR := Color("ffb000")
const WARNING_COLOR := Color("ff4b4b")

const COUNTDOWN_HOLD_SECONDS := 0.35
const GO_HOLD_SECONDS := 0.7
const WINNER_HOLD_SECONDS := 3.0

## Text pops in this big, then snaps down to normal size.
const POP_START_SCALE := 2.2
const POP_SECONDS := 0.35
const FADE_IN_SECONDS := 0.15
## Text drifts up to this size while fading out.
const EXIT_SCALE := 1.25
const EXIT_SECONDS := 0.2

const RACE_END_WARNING_FROM_SECONDS := 5

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
	_flash("%d" % count, COUNTDOWN_COLOR, COUNTDOWN_HOLD_SECONDS)


func _on_race_started() -> void:
	_flash("GO!", GO_COLOR, GO_HOLD_SECONDS)


func _on_first_finisher(car: Car) -> void:
	_flash("%s Wins!" % car.racer.display_name, WINNER_COLOR, WINNER_HOLD_SECONDS)
	_dnf_countdown_label.visible = true


func _on_finish_countdown_changed(count: int) -> void:
	_dnf_countdown_label.text = "Race ends in %d" % count
	if count <= RACE_END_WARNING_FROM_SECONDS:
		_dnf_countdown_label.add_theme_color_override("font_color", WARNING_COLOR)


## Pops the text in large, settles with a slight overshoot, holds, then grows and fades out.
func _flash(text: String, color: Color, hold_seconds: float) -> void:
	if _flash_tween:
		_flash_tween.kill()

	var label = _announce_label
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.scale = Vector2.ONE * POP_START_SCALE
	label.modulate.a = 0.0
	label.visible = true

	_flash_tween = create_tween()

	# Pop in (TRANS_BACK overshoots a little) while fading in.
	_flash_tween.tween_property(label, "scale", Vector2.ONE, POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flash_tween.parallel().tween_property(label, "modulate:a", 1.0, FADE_IN_SECONDS)

	_flash_tween.tween_interval(hold_seconds)

	# Exit: grow a little while fading away.
	var exit_size := Vector2.ONE * EXIT_SCALE
	_flash_tween.tween_property(label, "scale", exit_size, EXIT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flash_tween.parallel().tween_property(label, "modulate:a", 0.0, EXIT_SECONDS)

	_flash_tween.finished.connect(_reset_label.bind(label))


func _reset_label(label: Label) -> void:
	label.visible = false
	label.scale = Vector2.ONE
	label.modulate.a = 1.0
