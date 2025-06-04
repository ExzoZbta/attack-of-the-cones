#version 410 core

in vs {
    vec3 position;
    vec3 normal;
    vec2 texCoord;
    vec4 worldPos;
} fs_in;

out vec4 fragColor;

uniform float uTime;
uniform vec3 uCameraPosition;
uniform vec3 uLightPosition;

// Noise function as provided
float noise(vec2 uv) {
    return fract(sin(uv.x * 113. + uv.y * 412.) * 6339.);
}

vec3 noiseSmooth(vec2 uv) {
    vec2 index = floor(uv);
    
    vec2 pq = fract(uv);
    pq = smoothstep(0., 1., pq);
     
    float topLeft = noise(index);
    float topRight = noise(index + vec2(1, 0.));
    float top = mix(topLeft, topRight, pq.x);
    
    float bottomLeft = noise(index + vec2(0, 1));
    float bottomRight = noise(index + vec2(1, 1));
    float bottom = mix(bottomLeft, bottomRight, pq.x);
    
    return vec3(mix(top, bottom, pq.y));
}

// 3D Noise function
float noise3D(vec3 p) {
    vec2 uv = vec2(p.x, p.y) * 0.5 + 0.5;
    vec2 uv2 = vec2(p.y, p.z) * 0.5 + 0.5;
    vec2 uv3 = vec2(p.z, p.x) * 0.5 + 0.5;
    
    float n1 = noise(uv);
    float n2 = noise(uv2);
    float n3 = noise(uv3);
    
    return (n1 + n2 + n3) / 3.0;
}

vec3 noiseSmooth3D(vec3 p) {
    vec3 n1 = noiseSmooth(vec2(p.x, p.y) + uTime * 0.01);
    vec3 n2 = noiseSmooth(vec2(p.y, p.z) + uTime * 0.015);
    vec3 n3 = noiseSmooth(vec2(p.z, p.x) + uTime * 0.008);
    
    return (n1 + n2 + n3) / 3.0;
}

// Creates a soft, irregular particle shape for sand/dust
float sandParticle(vec2 center) {
    // Get distance from fragment to point center
    float dist = length(gl_PointCoord - center);
    
    // Create irregular dust/sand particle shape
    float noise1 = noise(gl_PointCoord * 12.0 + vec2(uTime * 0.05, 0.0));
    float noise2 = noise(gl_PointCoord * 18.0 - vec2(0.0, uTime * 0.03));
    
    // Combine noise for irregular shape
    float irregularity = mix(noise1, noise2, 0.5) * 0.3; // 30% irregularity
    
    // Add slight elongation for wind-blown appearance
    vec2 windDir = vec2(0.2, 0.05); // Slight horizontal bias
    float windEffect = dot(gl_PointCoord - center, windDir) * 0.2;
    
    // Soft edge with irregularity and wind effect
    return smoothstep(0.5 + irregularity + windEffect, 0.0, dist);
}

void main() {
    vec3 worldPos = fs_in.worldPos.xyz;
    
    // Calculate sand particle shape with wind-blown appearance
    float particleShape = sandParticle(vec2(0.5));
    
    // Use world position for large-scale noise patterns
    // Slower movement for the overall sandstorm pattern
    vec2 sandstormUV = worldPos.xz * 0.01 + uTime * vec2(0.004, 0.002);
    
    // Create larger swirling patterns for sandstorm movement
    float largeSwirl = noise(sandstormUV) * 0.6 + 0.4;
    
    // Add medium and fine detail
    float mediumDetail = noise(worldPos.xz * 0.05 + uTime * vec2(0.01, -0.008)) * 0.3;
    float fineDetail = noise(worldPos.xz * 0.2 + uTime * vec2(-0.02, 0.015)) * 0.1;
    
    // Combine for multi-scale sandstorm pattern
    float sandstormPattern = largeSwirl + mediumDetail + fineDetail;
    
    // Desert sand color palette
    vec3 sandLight = vec3(0.87, 0.77, 0.47); // Light sand
    vec3 sandMid = vec3(0.76, 0.65, 0.40);   // Medium sand
    vec3 sandDark = vec3(0.61, 0.53, 0.32);  // Dark sand
    
    // Apply height-based coloring for more realistic layering
    float heightFactor = smoothstep(-20.0, 20.0, worldPos.y);
    
    // Mix sand colors based on noise and height
    vec3 sandColor = mix(sandDark, sandMid, sandstormPattern);
    sandColor = mix(sandColor, sandLight, heightFactor * 0.5);
    
    // Distance from camera for fog effects
    float dist = length(worldPos - uCameraPosition);
    
    // Apply lighting effects
    float lightFactor = 0.3; // Ambient base
    
    // Directional sunlight (diffuse lighting)
    vec3 sunDir = normalize(vec3(0.4, 0.9, 0.2));
    lightFactor += max(0.0, dot(normalize(fs_in.normal), sunDir)) * 0.4;
    
    // Add point light contribution
    vec3 toLight = normalize(uLightPosition - worldPos);
    float lightDist = length(uLightPosition - worldPos);
    float pointLightStrength = 5.0 / (1.0 + lightDist * 0.2);
    lightFactor += max(0.0, dot(normalize(fs_in.normal), toLight)) * pointLightStrength * 0.3;
    
    // Apply lighting to color
    vec3 litColor = sandColor * lightFactor;
    
    // Enhanced distance fog effect for extreme sandstorm
    float fogFactor;

    // Always maintain extremely high density everywhere
    fogFactor = 0.95;

    // Calculate base alpha using distance and pattern - much higher base values
    float baseAlpha = mix(0.7, 0.95, sandstormPattern);

    // Apply particle shape but maintain high opacity
    float alpha = max(baseAlpha * particleShape, 0.6);

    // Distance-based alpha adjustments - maintain extreme density at all distances
    if (dist < 5.0) {
        // When very close, still maintain substantial opacity
        alpha = mix(0.7, alpha, 0.5);
    } else if (dist > 20.0) {
        // When farther away, make it nearly opaque to obscure skybox
        alpha = mix(alpha, 0.95, smoothstep(20.0, 80.0, dist));
    }

    // Final alpha clamping with very high minimum for extreme sandstorm
    alpha = clamp(alpha, 0.6, 0.95);

    // Darken the color slightly to create a more oppressive effect
    litColor *= 0.85;

    // Output final color with high transparency
    fragColor = vec4(litColor, alpha);
}