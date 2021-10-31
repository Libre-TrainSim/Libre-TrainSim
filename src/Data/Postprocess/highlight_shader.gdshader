shader_type canvas_item;

uniform vec4 highlight_color: hint_color = vec4(1.0, 0.0, 0.0, 0.25);

// converts the texture to a binary texture
// which means only black or white, depending on if a pixel contains information
// or not. 
int tex_bin(sampler2D tex, vec2 uv) {
	vec3 rgb = texture(tex, uv).xyz;
	if((rgb) == vec3(0)) {
		return 0;
	} else {
		return 1;
	}
}

void fragment() {
	if (tex_bin(TEXTURE, UV) == 0) {
		discard;
	} else {
		COLOR = highlight_color;
	}
}