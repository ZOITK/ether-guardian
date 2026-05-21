shader_type canvas_item;

uniform sampler2D y_texture;
uniform sampler2D cbcr_texture;

void fragment() {
	// YUV to RGB 표준 변환
	float y = texture(y_texture, UV).r;
	vec2 cbcr = texture(cbcr_texture, UV).rg;

	float r = y + 1.402 * (cbcr.g - 0.5);
	float g = y - 0.344136 * (cbcr.r - 0.5) - 0.714136 * (cbcr.g - 0.5);
	float b = y + 1.772 * (cbcr.r - 0.5);

	// 디버그: Y값이 0 근처면 문제 있음
	// 만약 Y값이 0.1보다 작으면 빨간색으로 표시 (카메라 신호 없음)
	if (y < 0.1) {
		COLOR = vec4(1.0, 0.0, 0.0, 1.0); // 빨간색 = 신호 없음
	} else {
		COLOR = vec4(r, g, b, 1.0);
	}
}
