shader_type canvas_item;

uniform vec4 fill_colour : source_color = vec4(
	0.051,
	0.129,
	0.278,
	0.88
);

uniform vec4 border_colour : source_color = vec4(
	0.808,
	0.475,
	0.824,
	0.9
);

uniform float corner_radius : hint_range(
	0.0,
	0.25
) = 0.10;

uniform float border_width : hint_range(
	0.0,
	0.1
) = 0.018;

uniform float edge_softness : hint_range(
	0.001,
	0.02
) = 0.003;


float rounded_box(
	vec2 point,
	vec2 half_size,
	float radius
) {
	vec2 distance = (
		abs(point)
		- half_size
		+ radius
	);

	return (
		min(
			max(
				distance.x,
				distance.y
			),
			0.0
		)
		+ length(
			max(
				distance,
				vec2(0.0)
			)
		)
		- radius
	);
}


void fragment() {
	float distance_to_edge = rounded_box(
		UV - vec2(0.5),
		vec2(0.5),
		corner_radius
	);

	float outer_alpha = (
		1.0
		- smoothstep(
			-edge_softness,
			edge_softness,
			distance_to_edge
		)
	);

	float inner_area = (
		1.0
		- smoothstep(
			-border_width - edge_softness,
			-border_width + edge_softness,
			distance_to_edge
		)
	);

	vec4 final_colour = mix(
		border_colour,
		fill_colour,
		inner_area
	);

	// Slight vertical shading gives the panel
	// more depth.
	final_colour.rgb *= mix(
		1.08,
		0.82,
		UV.y
	);

	final_colour.a *= outer_alpha;

	COLOR = final_colour;
}