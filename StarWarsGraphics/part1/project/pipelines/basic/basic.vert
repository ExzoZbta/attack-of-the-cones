#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;
//layout(location=2) in vec2 aTexture;

out vs{
    vec3 normal;
    vec3 fragPos;
//    vec2 texCoord;
} vs_out;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main()
{
    // Calculate fragment position in world space for lighting calculations
    vs_out.fragPos = vec3(uModel * vec4(aPosition, 1.0));
    
    // Calculate normal in world space
    vs_out.normal = mat3(transpose(inverse(uModel))) * aNormal;
    
//    vs_out.texCoord = aTexture;

    vec4 finalPosition = uProjection * uView * uModel * vec4(aPosition, 1.0f);

    // Note: Something subtle, but we need to use the finalPosition.w to do the perspective divide
    gl_Position = vec4(finalPosition.x, finalPosition.y, finalPosition.z, finalPosition.w);
}