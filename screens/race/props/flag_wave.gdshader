shader_type spatial;
// Draw both sides of the cloth.
render_mode cull_disabled;

uniform sampler2D flag_texture : source_color, filter_linear_mipmap;
uniform float wave_height = 0.15;      // metres at scale 1
uniform float waves_along_flag = 1.5;  // how many ripples fit on the flag
uniform float wave_speed = 3.0;
uniform float flag_width = 2.0;        // matches the model, used for the lighting slope

void vertex() {
	// UV.x is 0 at the pole and 1 at the free edge.
	float distance_from_pole = UV.x;
	// Squared, so the cloth near the pole barely moves.
	float freedom = distance_from_pole * distance_from_pole;

	// Each placed flag gets a different start point, so they don't wave in sync.
	float flag_offset = NODE_POSITION_WORLD.x + NODE_POSITION_WORLD.z;

	float ripple_frequency = waves_along_flag * TAU;
	float wave_angle = distance_from_pole * ripple_frequency - TIME * wave_speed + flag_offset;

	// Push the point in/out of the flag's plane.
	VERTEX.z += sin(wave_angle) * wave_height * freedom;

	// Tilt the normal to match the wave's slope, so the folds catch the light.
	float slope_per_uv = wave_height * (2.0 * distance_from_pole * sin(wave_angle)
		+ freedom * ripple_frequency * cos(wave_angle));
	float slope = slope_per_uv / flag_width;
	NORMAL = normalize(vec3(-slope, 0.0, 1.0));
}

void fragment() {
	ALBEDO = texture(flag_texture, UV).rgb;
	ROUGHNESS = 0.9;
}