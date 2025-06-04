/// Instanced light cubes that fire from spheres
module instancedlightcubes;

import bindbc.opengl;
import std.stdio;
import std.math;
import geometry;
import geometry.cube;
import linear;
import error;
import std.random;
import instancedsphereonobj;

// Struct to store light data
struct LightData {
    vec3 position;
    vec3 direction;
    float currentDistance;
    bool active;
}

/// Geometry that renders instanced light cubes
class InstancedLightCubes : ISurface {
    GLuint mVBO;         // Vertex buffer
    GLuint mIBO;         // Index buffer
    GLuint mInstanceVBO; // Instance buffer
    SurfaceCube mBaseSurface; // Base cube
    LightData[] mLightData; // Array of light data
    int mInstanceCount;  // Number of instances
    InstancedSphereOnObjSurface mParentSpheres; // Parent spheres
    float mLightSpeed = 0.1f;
    float mLightMaxDistance = 10.0f;
    float mLightCubeSize = 0.05f;
    float mTime = 0.0f;
    
    /// Constructor
    this(InstancedSphereOnObjSurface parentSpheres) {
        // Create base cube
        mBaseSurface = new SurfaceCube();
        mParentSpheres = parentSpheres;
        mInstanceCount = parentSpheres.mInstanceCount;
        
        // Initialize light data
        InitializeLightData();
        
        // Setup buffer
        SetupInstanceBuffer();
    }

    /// Convert quaternion to Euler angles
    vec3 QuaternionToEuler(vec4 q) {
        vec3 angles;
        
        // Roll (x-axis rotation)
        float sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
        float cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
        angles.x = atan2(sinr_cosp, cosr_cosp);
        
        // Pitch (y-axis rotation)
        float sinp = 2 * (q.w * q.y - q.z * q.x);
        if (abs(sinp) >= 1)
            angles.y = copysign(PI / 2, sinp);
        else
            angles.y = asin(sinp);
        
        // Yaw (z-axis rotation)
        float siny_cosp = 2 * (q.w * q.z + q.x * q.y);
        float cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
        angles.z = atan2(siny_cosp, cosy_cosp);
        
        return angles;
    }

    /// Get forward direction from quaternion (clone trooper facing direction)
    vec3 GetForwardDirectionFromQuaternion(vec4 q) {
        // Convert quaternion to rotation matrix
        float xx = q.x * q.x;
        float xy = q.x * q.y;
        float xz = q.x * q.z;
        float xw = q.x * q.w;
        
        float yy = q.y * q.y;
        float yz = q.y * q.z;
        float yw = q.y * q.w;
        
        float zz = q.z * q.z;
        float zw = q.z * q.w;
        
        // Extract forward vector (z-axis) from rotation matrix
        vec3 forward;
        forward.x = 2 * (xz + yw);
        forward.y = 2 * (yz - xw);
        forward.z = 1 - 2 * (xx + yy);
        
        return forward.Normalize();
    }
    
    /// Initialize light data for all spheres
    void InitializeLightData() {
        mLightData = new LightData[mInstanceCount];
        
        // Initialize lights from all spheres
        for (int i = 0; i < mInstanceCount; i++) {
            // Get sphere position, scale, and rotation data
            vec3 spherePosition = mParentSpheres.mInstanceData[i].position;
            vec3 sphereScale = mParentSpheres.mInstanceData[i].scale;
            vec4 sphereRotation = mParentSpheres.mInstanceData[i].rotation;
            
            // Get the forward direction based on the sphere's rotation (quaternion)
            vec3 forwardDirection = GetForwardDirectionFromQuaternion(sphereRotation);
            
            // Place light on sphere's surface in the forward direction
            vec3 startPosition = spherePosition + forwardDirection * sphereScale.x;
            
            // Initialize light data
            mLightData[i].position = startPosition;
            mLightData[i].direction = forwardDirection;
            mLightData[i].currentDistance = 0.0f;
            mLightData[i].active = true;
        }
    }
    
    /// Update all lights
    void Update() {
        // Update light positions
        for (int i = 0; i < mInstanceCount; i++) {
            // Update distance tracker
            mLightData[i].currentDistance += mLightSpeed;
            
            // Move the light in its direction (direct vector addition)
            mLightData[i].position = mLightData[i].position + mLightData[i].direction * mLightSpeed;
            
            // Check if light has reached max distance
            if (mLightData[i].currentDistance >= mLightMaxDistance) {
                // Get sphere position, scale, and rotation
                vec3 spherePosition = mParentSpheres.mInstanceData[i].position;
                vec3 sphereScale = mParentSpheres.mInstanceData[i].scale;
                vec4 sphereRotation = mParentSpheres.mInstanceData[i].rotation;
                
                // Get the forward direction based on the sphere's rotation
                vec3 forwardDirection = GetForwardDirectionFromQuaternion(sphereRotation);
                
                // Reset position to start from the sphere's surface again
                // Place it a bit farther from the sphere to avoid overlapping
                mLightData[i].position = spherePosition + forwardDirection * (sphereScale.x * 1.2f);
                mLightData[i].direction = forwardDirection;
                mLightData[i].currentDistance = 0.0f;
                
                // Always keep lasers active
                mLightData[i].active = true;
            } 
        }
        // Update instance buffer with new positions
        UpdateInstanceBuffer();
        mTime += 0.01f;
    }

    /// Get all light positions (for use with shader)
    LightData[] GetLightData() {
        return mLightData;
    }
    
    /// Get the closest light position for lighting calculations
    vec3 GetClosestLightPosition(vec3 point) {
        float minDist = float.max;
        vec3 closestPosition = mLightData[0].position;
        
        // Find closest light
        for (int i = 0; i < mInstanceCount; i++) {
            if (mLightData[i].active) {
                float dist = (mLightData[i].position - point).Magnitude();
                if (dist < minDist) {
                    minDist = dist;
                    closestPosition = mLightData[i].position;
                }
            }
        }
        
        return closestPosition;
    }

    /// Get N closest lights to a point
    LightData[] GetNClosestLights(vec3 point, int count) {
        // Create array to store distance/index pairs
        struct LightDistancePair {
            float distance;
            int index;
        }
        
        LightDistancePair[] distancePairs = new LightDistancePair[mInstanceCount];
        
        // Calculate distances for all active lights
        int activeCount = 0;
        for (int i = 0; i < mInstanceCount; i++) {
            if (mLightData[i].active) {
                distancePairs[activeCount].distance = (mLightData[i].position - point).Magnitude();
                distancePairs[activeCount].index = i;
                activeCount++;
            }
        }
        
        // Sort by distance (simple bubble sort)
        for (int i = 0; i < activeCount - 1; i++) {
            for (int j = 0; j < activeCount - i - 1; j++) {
                if (distancePairs[j].distance > distancePairs[j + 1].distance) {
                    // Swap
                    LightDistancePair temp = distancePairs[j];
                    distancePairs[j] = distancePairs[j + 1];
                    distancePairs[j + 1] = temp;
                }
            }
        }
        
        // Cap the count to the number of active lights
        int resultCount = count < activeCount ? count : activeCount;
        
        // Create result array with the closest lights
        LightData[] result = new LightData[resultCount];
        for (int i = 0; i < resultCount; i++) {
            result[i] = mLightData[distancePairs[i].index];
        }
        
        return result;
    }
    
    /// Setup the instance buffer
    void SetupInstanceBuffer() {
        // Get VAO from base surface
        mVAO = mBaseSurface.mVAO;
        
        // Bind the VAO
        glBindVertexArray(mVAO);
        
        // Create instance VBO
        glGenBuffers(1, &mInstanceVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mInstanceVBO);
        
        // Calculate buffer size and fill it - Now includes emission intensity
        GLfloat[] instanceBuffer = new GLfloat[mInstanceCount * 7]; // 7 floats per instance
        
        for (int i = 0; i < mInstanceCount; i++) {
            // Calculate the base index for this instance
            int baseIndex = i * 7;
            
            // Position (3 floats)
            instanceBuffer[baseIndex] = mLightData[i].position.x;
            instanceBuffer[baseIndex + 1] = mLightData[i].position.y;
            instanceBuffer[baseIndex + 2] = mLightData[i].position.z;
            
            // Direction (3 floats)
            instanceBuffer[baseIndex + 3] = mLightData[i].direction.x;
            instanceBuffer[baseIndex + 4] = mLightData[i].direction.y;
            instanceBuffer[baseIndex + 5] = mLightData[i].direction.z;
            
            // Emission intensity (1 float)
            instanceBuffer[baseIndex + 6] = 1.0f;
        }
        
        // Upload instance data to GPU
        glBufferData(GL_ARRAY_BUFFER, instanceBuffer.length * GLfloat.sizeof, 
                    instanceBuffer.ptr, GL_DYNAMIC_DRAW); // Use DYNAMIC_DRAW since we'll update frequently
        
        // Setup instance attributes (position, direction, and emission)
        glEnableVertexAttribArray(3); // Position attribute
        glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)0);
        glVertexAttribDivisor(3, 1); // One position per instance
        
        glEnableVertexAttribArray(4); // Direction attribute
        glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(3 * GLfloat.sizeof));
        glVertexAttribDivisor(4, 1); // One direction per instance
        
        glEnableVertexAttribArray(5); // Emission intensity attribute
        glVertexAttribPointer(5, 1, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(6 * GLfloat.sizeof));
        glVertexAttribDivisor(5, 1); // One emission value per instance
        
        // Unbind
        glBindVertexArray(0);
    }
    
    /// Update the instance buffer with new light positions
    void UpdateInstanceBuffer() {
        // Bind the instance buffer
        glBindBuffer(GL_ARRAY_BUFFER, mInstanceVBO);
        
        // Calculate the total buffer size needed
        GLfloat[] instanceBuffer = new GLfloat[mInstanceCount * 7]; // 7 floats per instance now
        
        for (int i = 0; i < mInstanceCount; i++) {
            // Calculate the base index for this instance
            int baseIndex = i * 7; // Use 7 instead of 6
            
            // Position (3 floats)
            instanceBuffer[baseIndex] = mLightData[i].position.x;
            instanceBuffer[baseIndex + 1] = mLightData[i].position.y;
            instanceBuffer[baseIndex + 2] = mLightData[i].position.z;
            
            // Direction (3 floats)
            instanceBuffer[baseIndex + 3] = mLightData[i].direction.x;
            instanceBuffer[baseIndex + 4] = mLightData[i].direction.y;
            instanceBuffer[baseIndex + 5] = mLightData[i].direction.z;
            
            // Emission intensity (1 float)
            instanceBuffer[baseIndex + 6] = 1.0f;
        }
        
        // Upload updated data
        glBufferSubData(GL_ARRAY_BUFFER, 0, instanceBuffer.length * GLfloat.sizeof, instanceBuffer.ptr);
        
        // Unbind
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    /// Render all light cubes
    override void Render() {
        // Bind VAO
        glBindVertexArray(mVAO);
        
        // Draw instanced
        glDrawElementsInstanced(
            GL_TRIANGLES,
            36,
            GL_UNSIGNED_INT,
            null,
            mInstanceCount
        );
        
        // Unbind
        glBindVertexArray(0);
    }
}