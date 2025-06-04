// ArchitPSET8/part1/project/pipelines/instancedlight/instancedlight.frag
#version 410 core

in vs{
    vec3 normal;
    vec4 position;
    vec3 instancePos;
    vec3 instanceDir;
    float distFromCenter;
    float emissionIntensity;
} fs_in;

out vec4 fragColor;

void main()
{
    // Light cubes are blue
    vec3 laserColor = vec3(0.2, 0.6, 2.5);
    // Calculate how far we are from the center of the bolt
    // This creates a sphere-like appearance instead of a cube
    float dist = fs_in.distFromCenter;
    
    // If too far from center, discard the fragment to create a rounded appearance
    if (dist > 0.95) {
        discard;
    }
    
    // Create a bright core with a subtle glow
    float intensity = 1.5 - (dist * dist * 0.5);
    intensity = clamp(intensity, 0.0, 2.0);
    
    // Add a bright highlight to the center
    if (dist < 0.4) {
        intensity = mix(intensity, 2.5, 0.9);
    }

    // Apply the emission intensity from the instance data
    intensity *= fs_in.emissionIntensity;
    
    // Output very bright blue color with rounded shape and instance-specific emission
    vec3 result = laserColor * intensity;
    
    // Add more brightness to the center - bright blue/white core
    result += vec3(0.4, 0.8, 1.5) * pow(1.0 - dist, 4.0) * fs_in.emissionIntensity;
    
    // Ensure very bright center even at grazing angles - almost white at center for intensity
    result = mix(result, vec3(1.0, 1.5, 3.0) * fs_in.emissionIntensity, pow(1.0 - dist, 5.0)); 
    
    // Final color with full opacity and no intensity capping
    // Allow overbright values to create bloom/glow effect
    fragColor = vec4(result, 1.0);
}