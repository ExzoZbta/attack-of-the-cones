#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;
layout(location=2) in vec2 aTextureCoord; 

// Instance attributes
layout(location=3) in vec3 aInstancePos;   // Position offset for this instance
layout(location=4) in vec3 aInstanceScale; // Scale for this instance
layout(location=5) in vec4 aInstanceRot;   // Rotation as quaternion

out vs{
    vec3 normal;
    vec3 fragPos;
    vec2 texCoord;
} vs_out;

uniform mat4 uView;
uniform mat4 uProjection;

// Helper function to create rotation matrix from quaternion
mat4 quatToMat4(vec4 q) {
    float qw = q.w;
    float qx = q.x;
    float qy = q.y;
    float qz = q.z;
    
    return mat4(
        1.0 - 2.0*qy*qy - 2.0*qz*qz, 2.0*qx*qy - 2.0*qz*qw, 2.0*qx*qz + 2.0*qy*qw, 0.0,
        2.0*qx*qy + 2.0*qz*qw, 1.0 - 2.0*qx*qx - 2.0*qz*qz, 2.0*qy*qz - 2.0*qx*qw, 0.0,
        2.0*qx*qz - 2.0*qy*qw, 2.0*qy*qz + 2.0*qx*qw, 1.0 - 2.0*qx*qx - 2.0*qy*qy, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

void main()
{
    // Create model matrix from instance data
    mat4 scaleMatrix = mat4(
        aInstanceScale.x, 0.0, 0.0, 0.0,
        0.0, aInstanceScale.y, 0.0, 0.0,
        0.0, 0.0, aInstanceScale.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
    
    mat4 rotMatrix = quatToMat4(aInstanceRot);
    
    mat4 transMatrix = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        aInstancePos.x, aInstancePos.y, aInstancePos.z, 1.0
    );
    
    // Combine transformations: position = trans * rot * scale * vertex
    mat4 modelMatrix = transMatrix * rotMatrix * scaleMatrix;
    
    // Calculate fragment position in world space for lighting calculations
    vs_out.fragPos = vec3(modelMatrix * vec4(aPosition, 1.0));
    
    // Calculate normal in world space
    vs_out.normal = mat3(transpose(inverse(modelMatrix))) * aNormal;

    // Pass texture coordinates to fragment shader
    vs_out.texCoord = aTextureCoord;

    // Calculate final position with view and projection
    gl_Position = uProjection * uView * modelMatrix * vec4(aPosition, 1.0f);
}