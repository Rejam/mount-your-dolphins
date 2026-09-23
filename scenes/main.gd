extends Node3D
## Runs the race: spawns cars, steers them round the track, and resets any
## that stop making progress.

const CAR_SCENE = preload("uid://ch1ph3v6ippq6")

@export var car_count := 3
## Distance between grid rows, in metres.
@export var grid_spacing := 2.5

@export_group("Driving")
@export var top_speed := 12.0
@export var corner_speed := 6.0
## How far ahead to aim, in metres, plus extra per m/s of speed.
@export var lookahead_base := 2.5
@export var lookahead_per_speed := 0.35
## How far ahead to look for bends when choosing a speed.
@export var corner_scan := 10.0

@export_group("Recovery")
## Seconds without progress before a car is reset.
@export var stuck_time := 2.0
## Metres a car must gain within stuck_time to count as progressing.
@export var min_progress := 1.0
## How far past its best point a car is placed when reset.
@export var reset_ahead := 3.0

@export_group("Variance")
## How far cars drift across the road, 0 (centre only) .. 1 (wall to wall).
@export_range(0.0, 1.0) var lane_wander := 0.8
## How often cars change line, in lane changes per metre (roughly).
@export var lane_change_rate := 0.03
## How much pace varies, e.g. 0.15 = up to 15% faster or slower.
@export_range(0.0, 0.5) var pace_variance := 0.15
## How often pace changes, per second (roughly).
@export var pace_change_rate := 0.1


## Race state for one car.
class Racer:
	var car: VehicleBody3D
	## Picks this car's slice of the variance noise.
	var index := 0
	## -1 (left) .. 1 (right).
	var lane := 0.0
	var last_progress := 0.0
	## Distance along the track, counting laps. Negative behind the start line.
	var distance := 0.0
	var best := 0.0
	var checkpoint := 0.0
	var stuck_timer := 0.0


@onready var track: RaceTrack = $Track
@onready var cars_root: Node3D = $Cars
@onready var race_camera: RaceCamera = $RaceCamera

var racers: Array[Racer] = []
var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	_noise.frequency = 1.0
	_noise.seed = randi()
	for i in car_count:
		var racer := Racer.new()
		racer.index = i
		racer.lane = -0.5 if i % 2 == 0 else 0.5
		racer.car = CAR_SCENE.instantiate()
		racer.car.name = "Car%d" % (i + 1)
		cars_root.add_child(racer.car)
		_place(racer, -(floori(i / 2.0) + 1) * grid_spacing)
		racers.append(racer)
	race_camera.set_targets(racers.map(func(r: Racer) -> Node3D: return r.car))


func _physics_process(delta: float) -> void:
	_time += delta
	for racer in racers:
		_update_progress(racer)
		_check_stuck(racer, delta)
		_steer(racer, delta)


func _update_progress(racer: Racer) -> void:
	var progress := track.get_progress(racer.car.global_position)
	var step := progress - racer.last_progress
	# Crossing the start line wraps progress around.
	if step > track.length * 0.5:
		step -= track.length
	elif step < -track.length * 0.5:
		step += track.length
	racer.last_progress = progress
	racer.distance += step
	racer.best = maxf(racer.best, racer.distance)


func _check_stuck(racer: Racer, delta: float) -> void:
	if racer.best >= racer.checkpoint + min_progress:
		racer.checkpoint = racer.best
		racer.stuck_timer = 0.0
	else:
		racer.stuck_timer += delta
		if racer.stuck_timer >= stuck_time:
			_place(racer, racer.best + reset_ahead)


func _steer(racer: Racer, delta: float) -> void:
	# Each car reads its own row of the noise: lane varies along the track,
	# pace varies over time.
	var row := racer.index * 100.0
	racer.lane = clampf(_noise.get_noise_2d(row, racer.distance * lane_change_rate) * lane_wander, -1.0, 1.0)
	var pace := 1.0 + _noise.get_noise_2d(row + 50.0, _time * pace_change_rate) * pace_variance

	var speed: float = racer.car.get_speed()
	var lookahead := lookahead_base + maxf(speed, 0.0) * lookahead_per_speed
	var target := track.sample_lane_point(racer.distance + lookahead, racer.lane)
	# Slow down in proportion to how sharply the track bends ahead.
	var bend := track.sample_tangent(racer.distance).angle_to(track.sample_tangent(racer.distance + corner_scan))
	var target_speed := lerpf(top_speed, corner_speed, clampf(bend / (PI * 0.5), 0.0, 1.0))
	racer.car.drive_toward(target, target_speed * pace, delta)


## Put a car on the track at a distance, in its lane, and reset its race state there.
func _place(racer: Racer, at_distance: float) -> void:
	var spot := track.get_lane_transform(at_distance, racer.lane)
	spot.origin += spot.basis.y * 0.3
	racer.car.reset_to(spot)
	racer.distance = at_distance
	racer.best = at_distance
	racer.checkpoint = at_distance
	racer.last_progress = wrapf(at_distance, 0.0, track.length)
	racer.stuck_timer = 0.0
