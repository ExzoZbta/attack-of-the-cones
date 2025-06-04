#version 410 core

// Input from vertex shader
layout (location = 0) in vec2 TexCoord;
layout (location = 1) in vec3 Normal;
layout (location = 2) in vec3 FragPos;

// Output data
out vec4 FragColor;

// Texture samplers
uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2D normalMap;

// Texture availability flags
uniform int hasDiffuseMap;
uniform int hasSpecularMap;
uniform int hasNormalMap;

// Light properties
uniform vec3 lightPos;
uniform vec3 viewPos;

void main()
{
    // Debug: Check texture coordinate values
    if (TexCoord.x < 0.0 || TexCoord.x > 1.0 || TexCoord.y < 0.0 || TexCoord.y > 1.0) {
        // Texture coordinates out of range
        FragColor = vec4(1.0, 0.0, 0.0, 1.0); // Red
        return;
    }

    // Default values in case textures aren't available
    vec3 diffuseColor = vec3(0.7, 0.7, 0.7);
    vec3 specularColor = vec3(0.5, 0.5, 0.5);
    vec3 normal = normalize(Normal);
    
    // Sample from textures
    if (hasDiffuseMap == 1) {       
        diffuseColor = texture(diffuseMap, TexCoord).rgb;
    }
    
    if (hasSpecularMap == 1) {
        specularColor = texture(specularMap, TexCoord).rgb;
    }
    
    if (hasNormalMap == 1) {
        normal = normalize(texture(normalMap, TexCoord).rgb * 2.0 - 1.0);
    }
    
    // Calculate distance for attenuation
    float distance = length(lightPos - FragPos);
    float attenuation = 1.0 / (1.0 + 0.5 * distance + 0.2 * distance * distance);
    
    // Ambient lighting
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * diffuseColor;
    
    // Diffuse lighting
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * diffuseColor;
    
    // Specular lighting
    float specularStrength = 0.5;
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * specularColor;
    
    // Apply attenuation to diffuse and specular components
    diffuse *= attenuation;
    specular *= attenuation;
    
    // Combine results
    vec3 result = ambient + diffuse + specular;
    FragColor = vec4(result, 1.0);
}