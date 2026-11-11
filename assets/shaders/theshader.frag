#pragma header

uniform float;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453) * 2.0 - 1.0;
}

float offset(float blocks, vec2 uv) {
    return rand(vec2(floor(uv.y * blocks)));
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    vec4 fraggy = flixel_texture2D(bitmap, uv);
    
    fraggy.r = flixel_texture2D(bitmap, uv + vec2(offset(16.0, uv) * 0.03, 0.0)).r;
    fraggy.g = flixel_texture2D(bitmap, uv + vec2(offset(8.0, uv) * 0.03 * 0.16666666, 0.0)).g;
    fraggy.b = flixel_texture2D(bitmap, uv + vec2(offset(8.0, uv) * 0.03, 0.0)).b;

    gl_FragColor = fraggy;
}