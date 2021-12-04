shader_type canvas_item;

uniform float blur_amount: hint_range(0,5) = 1.7;
uniform vec4 tint_color: hint_color = vec4(0.2);

void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount) * tint_color;
}