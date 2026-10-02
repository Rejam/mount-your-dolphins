class_name BendMapDebug extends MeshInstance3D
## Paints the track's bend map onto the road as a coloured ribbon.
## Debug only: hide or delete the node to turn it off.

const SCENE_UID = "uid://dpplunasx3200"

## Colour from straight (left) to max sharpness (right).
@export var gradient: Gradient
## Sharpness that shows as the far end of the gradient. 0.1 is a 10 m radius bend.
@export var max_sharpness := 0.1
## Height above the road, so the ribbon doesn't flicker against the road surface.
@export var lift_above_road := 0.5
## Opacity of the ribbon, so the road still shows through.
@export_range(0.0, 1.0) var opacity := 0.5

var track: RaceTrack


static func create() -> BendMapDebug:
	return load(SCENE_UID).instantiate()


func _ready() -> void:
	var race := get_parent() as Race
	# The race spawns its track in its own _ready, which runs after ours
	await race.ready
	track = race.track
	if gradient == null:
		gradient = _default_gradient()
	mesh = _build_ribbon()
	material_override = _build_material()


func _build_ribbon() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var half_width := track.track_width * 0.5
	var sample_count := ceili(track.lap_length)

	# One extra sample so the strip joins back up at the start line
	for sample_index in sample_count + 1:
		var distance_from_start := sample_index
		var road := track.sample_transform(distance_from_start)

		var bend_warning := track.get_bend_warning(distance_from_start)
		# 0 = straight, 1 = at or beyond max_sharpness
		var gradient_position := clampf(bend_warning / max_sharpness, 0.0, 1.0)
		var colour := gradient.sample(gradient_position)
		colour.a *= opacity

		# Road's local X is across the road; points are global, mesh is local
		var left_edge := to_local(road * Vector3(-half_width, lift_above_road, 0.0))
		var right_edge := to_local(road * Vector3(half_width, lift_above_road, 0.0))

		surface.set_color(colour)
		surface.add_vertex(left_edge)
		surface.set_color(colour)
		surface.add_vertex(right_edge)

	return surface.commit()


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Strip winding flips with track direction, so draw both sides
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _default_gradient() -> Gradient:
	var default_gradient := Gradient.new()
	default_gradient.set_color(0, Color.GREEN)
	default_gradient.set_color(1, Color.RED)
	default_gradient.add_point(0.5, Color.YELLOW)
	return default_gradient
