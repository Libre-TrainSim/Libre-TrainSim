shader_type canvas_item;

uniform vec4 highlight_color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 laplace;
	
	// laplace edge detection (faster to calc than sobel!)
	laplace  =  8.0 * texture(TEXTURE, UV);
	laplace += -1.0 * texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x, 0.0));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x, 0.0));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(0.0, SCREEN_PIXEL_SIZE.y));
	laplace += -1.0 * texture(TEXTURE, UV + vec2(0.0, -SCREEN_PIXEL_SIZE.y));
	
	
	if(abs(laplace.x) < 0.001) {  // == 0
		discard;
	} else {
		COLOR = highlight_color;
	}
}