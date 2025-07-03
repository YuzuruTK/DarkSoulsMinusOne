shader_type canvas_item;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    float levels = 6.0;

    col.r = floor(col.r * levels) / (levels - 1.0);
    col.g = floor(col.g * levels) / (levels - 1.0);
    col.b = floor(col.b * levels) / (levels - 1.0);

    COLOR = col;
	//COLOR = vec4(1.0 - col.rgb, col.a);
}
