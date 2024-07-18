shader_type canvas_item;

void fragment() {
    float start = 0.33;
    float end = 0.66;
    
    // Use the mod function to repeat the texture within the repeated section
    vec2 repeated_uv = vec2(UV.x, mod(UV.y, end - start) + start);
    
    // Sample the texture
    COLOR = texture(TEXTURE, repeated_uv);
}
