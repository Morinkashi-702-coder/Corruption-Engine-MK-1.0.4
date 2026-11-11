#pragma header
vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv * openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap

uniform float distort = 3;

vec2 pincushionDistortion(in vec2 uv, float strength) {
    vec2 st = uv - 0.5;
    float uvA = atan(st.x, st.y);
    float uvD = dot(st, st);
    return 0.5 + vec2(sin(uvA), cos(uvA)) * sqrt(uvD) * (1.0 - strength * uvD);
}

void main() {
    float alpha = openfl_Alphav;
    vec2 p = pincushionDistortion(openfl_TextureCoordv, distort).xy;

    vec3 color = texture2D(iChannel0, p).rgb;
    gl_FragColor = vec4(color, texture2D(iChannel0, uv).w);
}