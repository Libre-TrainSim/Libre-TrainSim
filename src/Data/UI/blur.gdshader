shader_type canvas_item;

//Temp from conversion
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float blur_amount: hint_range(0,5) = 1.7;
uniform vec4 tint_color: source_color = vec4(0.2);

void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount) * tint_color;
}