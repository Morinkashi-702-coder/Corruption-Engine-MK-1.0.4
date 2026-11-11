#pragma header
#define PI 3.1415926535897932384626433832795

uniform float amount;

float hardEdge(in float dist)
{
    float distanceChange = fwidth(dist) * 0.5;
    return smoothstep(distanceChange, -distanceChange, dist);
}

float sdRing( in vec2 p, in vec2 n, in float r, in float th )
{
    p.x = abs(p.x);
    p = mat2(n.x,n.y,-n.y,n.x)*p;
    return max( abs(length(p)-r)-th*0.5,
        length(vec2(p.x,max(0.0,abs(r-p.y)-th*0.5)))*sign(p.x) );
}

vec2 rotate(vec2 samplePosition, float rotation){
    float angle = rotation;
    float sine = sin(angle);
    float cosine = cos(angle);
    return vec2(cosine * samplePosition.x + sine * samplePosition.y, cosine * samplePosition.y - sine * samplePosition.x);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    float t = PI*amount;
    vec2 cs = vec2(cos(t),sin(t));
    const float ra = 0.8;
    const float th = 0.3;

    float ringDist = sdRing(rotate((uv - vec2(0.5, 0.5)) * 2.0, -t), cs, ra, th);
    float erectDist = hardEdge(ringDist);
    float outlineDist = 1.0 - ringDist;
    vec4 color = vec4(erectDist, erectDist, erectDist, erectDist);

    if(outlineDist < 1.0 && outlineDist > 0.95)
        color = vec4(0.0, 0.0, 0.0, 1.0);
    
    if(hasTransform){
        if(hasColorTransform){
            mat4 colorMultiplier = mat4(0);
            colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
            colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
            colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
            colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
            
            color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
        }

        if(color.a > 0.0)
            color *= openfl_Alphav;
    }
        

    gl_FragColor = color;
}