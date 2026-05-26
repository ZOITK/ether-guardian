shader_type canvas_item;

uniform sampler2D y_texture;

void fragment() {
	// Y 채널(밝기)을 그레이스케일로 표시
	float y = texture(y_texture, UV).r;
	COLOR = vec4(y, y, y, 1.0);
}
