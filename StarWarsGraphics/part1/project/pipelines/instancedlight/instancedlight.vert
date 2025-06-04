#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;

// Instance attributes
layout(location=3) in vec3 aInstancePos;   // Position of this light instance
layout(location=4) in vec3 aInstanceDir;   // Direction of this light instance
layout(location=5) in float aEmissionIntensity; // Emission intensity of this light


out vs{
    vec3 normal;
    vec4 position;
    vec3 instancePos;
    vec3 instanceDir;
    float distFromCenter;
    float emissionIntensity;
} vs_out;

uniform mat4 uView;
uniform mat4 uProjection;

// Create a rotation matrix that aligns the cube to the direction vector
mat4 createRotationMatrix(vec3 direction) {
    // Find the rotation axis and angle to align the forward direction (0,0,1) with our desired direction
    // First, normalize the direction
    vec3 dir = normalize(direction);
    
    // Define the forward vector (the default direction of our elongated cube)
    vec3 forward = vec3(1.0, 0.0, 0.0);
    
    // Find the axis of rotation (cross product of forward and direction)
    vec3 axis = cross(forward, dir);
    
    // If the cross product is zero, handle the special case
    if (length(axis) < 0.000001) {
        // Check if vectors are parallel or anti-parallel
        if (dot(forward, dir) > 0.0) {
            // Vectors are parallel, no rotation needed
            return mat4(1.0);
        } else {
            // Vectors are anti-parallel, rotate 180 degrees around any perpendicular axis
            return mat4(
                -1.0, 0.0, 0.0, 0.0,
                0.0, 1.0, 0.0, 0.0,
                0.0, 0.0, -1.0, 0.0,
                0.0, 0.0, 0.0, 1.0
            );
        }
    }
    
    // Normalize the axis
    axis = normalize(axis);
    
    // Calculate the angle between forward and direction
    float angle = acos(dot(forward, dir));
    
    // Build the rotation matrix using the axis-angle formula
    float c = cos(angle);
    float s = sin(angle);
    float t = 1.0 - c;
    
    return mat4(
        t * axis.x * axis.x + c,           t * axis.x * axis.y - axis.z * s,  t * axis.x * axis.z + axis.y * s,  0.0,
        t * axis.x * axis.y + axis.z * s,  t * axis.y * axis.y + c,           t * axis.y * axis.z - axis.x * s,  0.0,
        t * axis.x * axis.z - axis.y * s,  t * axis.y * axis.z + axis.x * s,  t * axis.z * axis.z + c,           0.0,
        0.0,                               0.0,                               0.0,                                1.0
    );
}

void main()
{
    // Store the instance position and direction for later use
    vs_out.instancePos = aInstancePos;
    vs_out.instanceDir = aInstanceDir;
    vs_out.emissionIntensity = aEmissionIntensity;
    
    // Create rotation matrix to align the laser with its direction
    mat4 rotationMatrix = createRotationMatrix(aInstanceDir);
    
    // Create scaling matrix to make the cube into a tiny oval shape
    mat4 scaleMatrix = mat4(
        0.05, 0.0, 0.0, 0.0, 
        0.0, 0.03, 0.0, 0.0,  
        0.0, 0.0, 0.03, 0.0,  
        0.0, 0.0, 0.0, 1.0
    );
    
    // Translation matrix for the instance position
    mat4 translationMatrix = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        aInstancePos.x, aInstancePos.y, aInstancePos.z, 1.0
    );
    
    // Combine the matrices: first scale, then rotate to align with direction, then translate
    mat4 modelMatrix = translationMatrix * rotationMatrix * scaleMatrix;
    
    // Calculate normal
    vs_out.normal = mat3(transpose(inverse(modelMatrix))) * aNormal;
    vs_out.position = modelMatrix * vec4(aPosition, 1.0);

    // Calculate distance from center for sphere-like effect
    vec3 localPos = aPosition;
    vs_out.distFromCenter = length(localPos);
    
    // Calculate final position
    gl_Position = uProjection * uView * vs_out.position;
}