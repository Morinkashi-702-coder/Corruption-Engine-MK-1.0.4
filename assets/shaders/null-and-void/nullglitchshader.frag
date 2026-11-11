#pragma header

uniform vec2 iResolution;
uniform float iTime;

uniform float glitchAmplitude; // increase this
uniform float glitchNarrowness;
uniform float glitchBlockiness;
uniform float glitchMinimizer; // decrease this

float rand(vec2 p)
{
    float t = floor(iTime * 20.) / 10.;
    return fract(sin(dot(p, vec2(t * 12.9898, t * 78.233))) * 43758.5453);
}

float noise(vec2 uv, float blockiness)
{   
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    float n1 = rand(id);
    float n2 = rand(id+vec2(1,0));
    float n3 = rand(id+vec2(0,1));
    float n4 = rand(id+vec2(1,1));
    
    vec2 u = smoothstep(0.0, 1.0 + blockiness, lv);

    return mix(mix(n1, n2, u.x), mix(n3, n4, u.x), u.y);
}

float fbm(vec2 uv, int count, float blockiness, float complexity)
{
    float val = 0.0;
    float amp = 0.5;
    
    while(count != 0)
    {
        val += amp * noise(uv, blockiness);
        amp *= 0.5;
        uv *= complexity;    
        count--;
    }
    
    return val;
}

void main()
{
    vec2 fragCoord = openfl_TextureCoordv * iResolution;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 a = vec2(uv.x * (iResolution.x / iResolution.y), uv.y);
    vec2 uv2 = vec2(a.x / iResolution.x, exp(a.y));
    vec2 id = floor(uv * 8.0);
    //id.x /= floor(texture2D(bitmap, vec2(id / 8.0)).r * 8.0);

    // Generate shift amplitude
    float shift = glitchAmplitude * pow(fbm(uv2, int(rand(id) * 6.), glitchBlockiness, glitchNarrowness), glitchMinimizer);
    
    // Apply glitch and RGB shift
    float colR = flixel_texture2D(bitmap, vec2(uv.x + shift, uv.y)).r * (1. - shift) ;
    float colG = flixel_texture2D(bitmap, vec2(uv.x - shift, uv.y)).g * (1. - shift) + rand(id) * shift;
    float colB = flixel_texture2D(bitmap, vec2(uv.x - shift, uv.y)).b * (1. - shift);
    // Mix with the scanline effect
    vec3 f = vec3(colR, colG, colB) - (0.1);
    float alpha = flixel_texture2D(bitmap, uv).a;
    // Output to screen
    gl_FragColor = vec4(f, alpha);
}