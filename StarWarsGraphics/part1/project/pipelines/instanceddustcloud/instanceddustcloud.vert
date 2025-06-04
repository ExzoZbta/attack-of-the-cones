#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;
layout(location=2) in vec2 aTexCoord;

// Instance attributes
layout(location=3) in vec3 aInstancePos;   // Position offset for this instance
layout(location=4) in vec3 aInstanceScale; // Scale for this instance
layout(location=5) in vec4 aInstanceRot;   // Rotation as quaternion

out vs {
    vec3 position;
    vec3 normal;
    vec2 texCoord;
    vec4 worldPos;
} vs_out;

uniform mat4 uView;
uniform mat4 uProjection;
uniform float uTime;

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

void main() {
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
    
    // Pass position, normal and texture coord to fragment shader
    vs_out.position = aPosition;
    vs_out.normal = mat3(transpose(inverse(modelMatrix))) * aNormal;
    vs_out.texCoord = aTexCoord;
    
    // Calculate world position for fragment shader
    vs_out.worldPos = modelMatrix * vec4(aPosition, 1.0);
    
    // Add some time-based movement to the dust particles
    float displacement = sin(uTime * 0.2 + aPosition.x * 0.1 + aPosition.z * 0.1) * 0.2;
    vs_out.worldPos.y += displacement;
    
    // Calculate final position
    gl_Position = uProjection * uView * vs_out.worldPos;
}