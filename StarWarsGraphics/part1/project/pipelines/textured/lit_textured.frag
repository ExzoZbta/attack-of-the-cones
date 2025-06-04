#version 410 core

// Input from vertex shader
layout (location = 0) in vec2 TexCoord;

// Output data
out vec4 FragColor;

// Texture samplers
uniform sampler2D diffuseMap;

// Texture availability flags
uniform int hasDiffuseMap;

void main()
{
    // Default diffuse color
    vec3 diffuseColor = vec3(1.0, 1.0, 1.0);
    
    // Sample from diffuse texture if available
    if (hasDiffuseMap == 1) {       
        diffuseColor = texture(diffuseMap, TexCoord).rgb;
    }
    
    // Output fully lit color
    FragColor = vec4(diffuseColor, 1.0);
}