shader_type canvas_item;
uniform vec2 sprite_sheet_size = vec2(16, 16);

void fragment() {
	vec2 current_point = sprite_sheet_size * UV;
	vec4 texture_color = texture(TEXTURE, UV);
	if (current_point.y > 14.2 && texture_color.a > 0.0) {
		COLOR.a = 0.15;
	}
}
