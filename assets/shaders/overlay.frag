#pragma header 
          
uniform float rT;
uniform float gT;
uniform float bT;
uniform float rR;
uniform float gR;
uniform float bR;
uniform float ypos;
uniform float xpos;
uniform float amt;
uniform bool trans;
  
void main()
{
  vec3 neonPurple = vec3(rT,gT,bT);
  vec3 neonBlue = vec3(rR, gR, bR);

  vec2 uv = openfl_TextureCoordv;

  vec2 glowCenter = vec2(xpos, ypos);

  vec2 p = glowCenter - uv;
  
  vec2 glowCenter1 = vec2(1., 0.5);
  
  vec2 p1 = uv;
  
  float dist = 1./length(p);
  
  dist *=  amt;
  
  dist = pow(dist, 0.8);
  
  float dist1 = 1./length(p1);
  
  dist1 *= 0.;
  
  dist1 = pow(dist1, 0.5);
  
  // Output to screen
  vec4 glowColor = mix(vec4(neonBlue*dist1,0.5), vec4(neonPurple*dist,0.5), 0.7);
  gl_FragColor = flixel_texture2D(bitmap, uv.xy);
  gl_FragColor += glowColor;
  if (trans)
	  gl_FragColor = gl_FragColor;
  else
	  gl_FragColor = gl_FragColor * flixel_texture2D(bitmap, uv).a;
}