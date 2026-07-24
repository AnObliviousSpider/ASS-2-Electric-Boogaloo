shader_type canvas_item;


uniform sampler2D screen_texture
	: hint_screen_texture, filter_linear;

uniform float grain_strength
	: hint_range(0.0, 0.10) = 0.004;

uniform float scanline_strength
	: hint_range(0.0, 0.10) = 0.003;

uniform float horizontal_wobble
	: hint_range(0.0, 0.01) = 0.00015;

uniform float colour_separation
	: hint_range(0.0, 0.01) = 0.00008;

uniform float grain_speed
	: hint_range(1.0, 60.0) = 16.0;

uniform float horizontal_lines
	: hint_range(100.0, 1000.0) = 480.0;


float random_noise(vec2 position) {
	return fract(
		sin(
			dot(
				position,
				vec2(12.9898, 78.233)
			)
		) * 43758.5453
	);
}


void fragment() {
	vec2 uv = SCREEN_UV;

	float current_frame = floor(
		TIME * grain_speed
	);

	float horizontal_row = floor(
		uv.y * horizontal_lines
	);

	float row_noise = random_noise(
		vec2(
			horizontal_row,
			current_frame
		)
	);

	// Slightly shift individual horizontal lines.
	float line_offset = (
		row_noise - 0.5
	) * horizontal_wobble;

	uv.x += line_offset;

	uv = clamp(
		uv,
		vec2(0.0),
		vec2(1.0)
	);

	// Very subtle RGB separation.
	float red = texture(
		screen_texture,
		uv + vec2(colour_separation, 0.0)
	).r;

	float green = texture(
		screen_texture,
		uv
	).g;

	float blue = texture(
		screen_texture,
		uv - vec2(colour_separation, 0.0)
	).b;

	vec3 screen_colour = vec3(
		red,
		green,
		blue
	);

	// Horizontal brightness grain.
	float grain = (
		row_noise - 0.5
	) * grain_strength;

	// Soft alternating scanlines.
	float scanline = sin(
		uv.y * horizontal_lines * 3.14159265
	);

	scanline *= scanline_strength;

	screen_colour += grain;
	screen_colour -= abs(scanline);

	COLOR = vec4(
		screen_colour,
		1.0
	);
}