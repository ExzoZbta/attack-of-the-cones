#version 410 core

// Input vertex data
layout (location = 0) in vec3 aPosition;
layout (location = 2) in vec2 aTextureCoord;

// Output data
layout (location = 0) out vec2 TexCoord;

// Uniforms
uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main()
{
    // Transform position to clip space
    gl_Position = uProjection * uView * uModel * vec4(aPosition, 1.0);
    
    // Pass texture coordinates to fragment shader
    TexCoord = aTextureCoord;
}