#version 410 core

in vs{
    vec3 normal;
    vec3 fragPos;
    vec2 texCoord;
} fs_in;

out vec4 fragColor;

// Light position
uniform vec3 lightPos;
// View position
uniform vec3 viewPos;

// Texture samplers
uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2D normalMap;

// Texture availability flags
uniform int hasDiffuseMap;
uniform int hasSpecularMap;
uniform int hasNormalMap;

void main()
{
    // Default values in case textures aren't available
    vec3 diffuseColor = normalize(fs_in.normal) * 0.5 + 0.5; // Default color from normal
    vec3 specularColor = vec3(0.5);
    vec3 normal = normalize(fs_in.normal);
    
    // Sample from textures if available
    if (hasDiffuseMap == 1) {
        diffuseColor = texture(diffuseMap, fs_in.texCoord).rgb;
    }
    
    if (hasSpecularMap == 1) {
        specularColor = texture(specularMap, fs_in.texCoord).rgb;
    }
    
    if (hasNormalMap == 1) {
        normal = normalize(texture(normalMap, fs_in.texCoord).rgb * 2.0 - 1.0);
    }
    
    // White light
    vec3 lightColor = vec3(1.0);
    
    // Phong lighting model parameters
    float ambientStrength = 0.2;
    float diffuseStrength = 0.8;
    float specularStrength = 0.8;
    float shininess = 32.0;
    
    // Ambient component
    vec3 ambient = ambientStrength * lightColor;
    
    // Diffuse component
    vec3 lightDir = normalize(lightPos - fs_in.fragPos);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diffuseStrength * diff * lightColor;
    
    // Specular component
    vec3 viewDir = normalize(viewPos - fs_in.fragPos);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    vec3 specular = specularStrength * spec * specularColor;
    
    // Calculate distance for attenuation
    float distance = length(lightPos - fs_in.fragPos);
    float attenuation = 1.0 / (1.0 + 0.1 * distance + 0.01 * distance * distance);
    
    // Apply attenuation
    diffuse *= attenuation;
    specular *= attenuation;
    
    vec3 result = (ambient + diffuse + specular) * diffuseColor;
    fragColor = vec4(result, 1.0);
}