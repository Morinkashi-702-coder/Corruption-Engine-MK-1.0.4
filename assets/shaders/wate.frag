#pragma header
uniform float iTime;
uniform vec2 iResolution;
// A simple water shader. (c) Ajarus, viktor@ajarus.com.
//
// Attribution-ShareAlike CC License.

const float PI = 3.1415926535897932;

// play with these parameters to custimize the effect
// ==================================================

//speed
const float speed = 0.02;
const float speed_x = 0.03;
const float speed_y = 0.03;

// refraction
const float emboss = 0.30;
const float intensity = 1.4;
const int steps = 8;
const float frequency = 3.0;
const int angle = 7; // better when a prime

// reflection
const float delta = 60.;
const float gain = 700.;
const float reflectionCutOff = 0.012;
const float reflectionIntensity = 200000.;

// ===================================================


  float col(vec2 coord,float time)
  {
    float delta_theta = 2.0 * PI / float(angle);
    float col = 0.0;
    float theta = 0.0;
    for (int i = 0; i < steps; i++)
    {
      vec2 adjc = coord;
      theta = delta_theta*float(i);
      adjc.x += cos(theta)*time*speed + time * speed_x;
      adjc.y -= sin(theta)*time*speed - time * speed_y;
      col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*frequency)*intensity;
    }

    return cos(col);
  }

//---------- main

void main()
{
    float time = iTime*1.3;
    //vec2 iResolution = openfl_TextureSize;
    vec2 fragCoord = openfl_TextureCoordv * iResolution;
    

    vec2 p = (openfl_TextureCoordv), c1 = p, c2 = p;
    float cc1 = col(c1,time);

    c2.x += iResolution.x/delta;
    float dx = emboss*(cc1-col(c2,time))/delta;

    c2.x = p.x;
    c2.y += iResolution.y/delta;
    float dy = emboss*(cc1-col(c2,time))/delta;

    c1.x += dx*2.;
    c1.y = -(c1.y+dy*2.);

    float alpha = 1.+dot(dx,dy)*gain;
      
    float ddx = dx - reflectionCutOff;
    float ddy = dy - reflectionCutOff;
    if (ddx > 0. && ddy > 0.)
      alpha = pow(alpha, ddx*ddy*reflectionIntensity);
      
    vec4 col = flixel_texture2D(bitmap,c1);
    gl_FragColor = col;
}
