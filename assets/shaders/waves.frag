#pragma header
uniform float iTime;
vec2 uv = openfl_TextureCoordv.xy;
vec2 iResolution = openfl_TextureSize;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
uniform vec4      iMouse;   
#define texture flixel_texture2D
#define iChannel0 bitmap
#define iChannel1 bitmap
#define iChannel2 bitmap
#define fragColor gl_FragColor
#define mainImage main

const vec4 u_WaveStrengthX=vec4(0.0,0.0,0.000,0.00);
const vec4 u_WaveStrengthY=vec4(2.54,6.33,0.00102,0.0025);
vec2 dist(vec2 uv) { 
    float uTime = iTime * 0.05;
    if(uTime==0.0) uTime=0.15*iTime;
    float noise = texture(iChannel1, uTime + uv).r;
    uv.y += (cos((uv.y + uTime * u_WaveStrengthY.y + u_WaveStrengthY.x * noise)) * u_WaveStrengthY.z) +
        (cos((uv.y + uTime) * 30.0) * u_WaveStrengthY.w);

    uv.x += (sin((uv.y + uTime * u_WaveStrengthX.y + u_WaveStrengthX.x * noise)) * u_WaveStrengthX.z) +
        (sin((uv.y + uTime) * 45.0) * u_WaveStrengthX.w);
    return uv;
}
void mainImage(  )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec4 col = texture(iChannel0,dist(uv));

    // Output to screen
    fragColor = col;
}