class_name BoostDebug extends Node
## Test only: press B to boost a random car.

const BOOST_KEY := KEY_B


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var is_boost_press := key and key.pressed and not key.echo and key.keycode == BOOST_KEY
	if is_boost_press:
		_boost_followed_car()


func _boost_followed_car() -> void:
	var race := get_parent() as Race
	var car := race.race_camera.current_target as Car
	if not car:
		return
	var started := Boost.find_on(car).activate()
	print("Boost %s: %s" % [car.racer.display_name, started])
