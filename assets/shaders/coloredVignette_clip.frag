#pragma header

uniform float amount;
uniform float strength;

void main() {
    vec4 flixelColor = texture2D(bitmap, openfl_TextureCoordv);
    vec2 uv = openfl_TextureCoordv.xy;
    vec3 color = vec3(0.0,0.0,0.0);

    vec3 col = pow(texture2D(bitmap, uv).rgb, vec3(1.0 / strength));

    float vignette = mix(1.0, 1.0 - amount, distance(uv, vec2(0.5)));
    col = pow(mix(col * color, col, vignette), vec3(strength));

    gl_FragColor = vec4(col, flixelColor.a);
}
