shader_type canvas_item;

// converts the texture to a binary texture
// which means only black or white, depending on if a pixel contains information
// or not.
float tex_bin(sampler2D tex, vec2 uv) {
	vec3 rgb = texture(tex, uv).xyz;
	if(rgb == vec3(0)) {
		return 0.0;
	} else {
		return 1.0;
	}
}

void fragment() {
	float col = tex_bin(TEXTURE, UV);
	col = max(col, tex_bin(TEXTURE, UV + vec2(0.0, SCREEN_PIXEL_SIZE.y)));
	col = max(col, tex_bin(TEXTURE, UV + vec2(0.0, -SCREEN_PIXEL_SIZE.y)));
	col = max(col, tex_bin(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x, 0.0)));
	col = max(col, tex_bin(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x, 0.0)));
	col = max(col, tex_bin(TEXTURE, UV + SCREEN_PIXEL_SIZE.xy));
	col = max(col, tex_bin(TEXTURE, UV - SCREEN_PIXEL_SIZE.xy));
	col = max(col, tex_bin(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y)));
	col = max(col, tex_bin(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y)));
	COLOR = vec4(col);
}