shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 8.0) = 2.0;

void fragment() {
    vec4 color = vec4(0.0);
    vec2 pixel_size = SCREEN_PIXEL_SIZE * blur_amount;
    
    // Simple 9-sample blur
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(float(x), float(y)) * pixel_size);
        }
    }
    
    color = color / 9.0;
    
    // Convert to grayscale using luminance formula
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    COLOR = vec4(gray, gray, gray, color.a);
}