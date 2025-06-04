#version 410 core

in vs{
    vec3 normal;
    vec3 fragPos;
//    vec2 texCoord;
} fs_in;

out vec4 fragColor;

// light position
uniform vec3 lightPos;

void main()
{
    // vec3 lightPos = vec3(1.5, 0.5, 1.5);
    
    vec3 objectColor = normalize(fs_in.normal) * 0.5 + 0.5;
	// white color
    vec3 lightColor = vec3(1.0, 1.0, 1.0);
    
    // Phong lighting model parameters
    float ambientStrength = 0.2;
    float diffuseStrength = 0.8;
    float specularStrength = 0.8;
    float shininess = 32.0;
    
    // Camera position
    vec3 viewPos = vec3(0.0, 0.0, 5.0);
    
    // Ambient component
    vec3 ambient = ambientStrength * lightColor;
    
    // Diffuse component
    vec3 norm = normalize(fs_in.normal);
    vec3 lightDir = normalize(lightPos - fs_in.fragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diffuseStrength * diff * lightColor;
    
    // Specular component
    vec3 viewDir = normalize(viewPos - fs_in.fragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    vec3 specular = specularStrength * spec * lightColor;
    
    vec3 result = (ambient + diffuse + specular) * objectColor;
    fragColor = vec4(result, 1.0);
}