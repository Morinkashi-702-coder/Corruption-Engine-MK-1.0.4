#pragma header

uniform float brightness;
uniform float threshold;
uniform float directions;
uniform float quality;
uniform float size;

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    float Pi = 6.28318530718;
    vec4 color = texture2D(bitmap, uv);
    
    if (brightness <= 0.0 || size <= 0.0) {
        gl_FragColor = color;
        return;
    }

    vec4 bloom = vec4(0.0);
    float weightSum = 0.0;

    vec4 highlight = max(color - threshold, 0.0);

    for (float d = 0.0; d < Pi; d += Pi / directions) {
        for (float i = 1.0; i <= float(quality); i++) {
            float offset = (i / float(quality)) * size;
            float x_offset = (sin(d) * offset) / openfl_TextureSize.y;
            float y_offset = (cos(d) * offset) / openfl_TextureSize.x;
            vec2 sampleUV = clamp(uv + vec2(x_offset, y_offset), vec2(0.0), vec2(1.0));

            // Sample only the highlight areas
            vec4 sampleColor = max(texture2D(bitmap, sampleUV) - threshold, 0.0);
            float weight = exp(-2.0 * (i / float(quality))); // Smooth falloff
            bloom += sampleColor * weight;
            weightSum += weight;
        }
    }

    if (weightSum > 0.0) {
        bloom /= weightSum;
    }

    gl_FragColor = color + (bloom * brightness);
}