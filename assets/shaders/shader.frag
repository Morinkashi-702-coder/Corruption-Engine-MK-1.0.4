// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D

// variables which are empty, they need just to avoid crashing shader
uniform vec4 iMouse;

// end of ShadertoyToFlixel header

//-----------------------------------------------------
// SnowIsFalling.glsl -- SOLO NIEVE CAIENDO (SHADERTOY)
//-----------------------------------------------------

#define LAYERS 14

#define DEPTH1 .3
#define WIDTH1 .4
#define SPEED1 .6

#define DEPTH2 .1
#define WIDTH2 .3
#define SPEED2 .1

// Snow only, no background
float snowing(in vec2 uv, in vec2 fragCoord)
{
    const mat3 p = mat3(13.323122,23.5112,21.71123,
                        21.1212,28.7312,11.9312,
                        21.8112,14.7212,61.3934);
    vec2 mp = iMouse.xy / iResolution.xy;
    uv.x += mp.x * 4.0;
    mp.y *= 0.25;
    float depth = smoothstep(DEPTH1, DEPTH2, mp.y);
    float width = smoothstep(WIDTH1, WIDTH2, mp.y);
    float speed = smoothstep(SPEED1, SPEED2, mp.y);
    float acc = 0.0;
    float dof = 5.0 * sin(iTime * 0.1);
    for (int i = 0; i < LAYERS; i++)
    {
        float fi = float(i);
        vec2 q = uv * (1.0 + fi * depth);
        float w = width * mod(fi * 7.238917, 1.0) - width * 0.1 * sin(iTime * 2. + fi);
q += vec2(q.y * w, speed * (-iTime) / (1.0 + fi * depth * 0.03));
        vec3 n = vec3(floor(q), 31.189 + fi);
        vec3 m = floor(n) * 0.00001 + fract(n);
        vec3 mp = (31415.9 + m) / fract(p * m);
        vec3 r = fract(mp);
        vec2 s = abs(mod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);
        s += 0.01 * abs(2.0 * fract(10. * q.yx) - 1.);
        float d = 0.6 * max(s.x - s.y, s.x + s.y) + max(s.x, s.y) - .01;
        float edge = 0.05 + 0.05 * min(.5 * abs(fi - 5. - dof), 1.);
        acc += smoothstep(edge, -edge, d) * (r.x / (1. + .02 * fi * depth));
    }
    return acc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.y;
    float snowOut = snowing(uv, fragCoord);

    fragColor = vec4(vec3(snowOut), snowOut);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}