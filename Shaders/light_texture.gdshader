shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    float mask = texture(TEXTURE, UV).r;

    COLOR.rgb = vec3(1.0); // White
    COLOR.a = mask;        // White = opaque, Black = transparent
}
