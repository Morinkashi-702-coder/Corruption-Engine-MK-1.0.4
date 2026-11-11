#pragma header
#define iChannel0 bitmap

uniform float amount;
uniform float strength;

void main() {
    vec4 flixelColor = texture2D(iChannel0, openfl_TextureCoordv);
    vec2 uv = openfl_TextureCoordv.xy;
    float alpha = texture2D(iChannel0, uv).a;
    vec3 replacementColour = vec3(0.0,0.0,0.0);
    
    vec3 col = pow(texture2D(bitmap, uv).rgb, vec3(1.0 / strength));
    float vignette = mix(1.0, 1.0 - amount, distance(uv, vec2(0.5)));
    col = pow(mix(col * replacementColour, col, vignette), vec3(strength));
    
    gl_FragColor = vec4(col, flixelColor.a);
    
    //float vignette = mix(1.0, 1.0 - amount, distance(uv, vec2(0.5)));
    //float shapedVignette = pow(vignette, (1.0 / strength));  // stronger falloff
    //float vignetteStrength = 1.0 - shapedVignette;
    //vec3 vignetteColor = replacementColour * vignetteStrength;
    //gl_FragColor = flixelColor + vec4(vignetteColor, vignetteStrength);
}
