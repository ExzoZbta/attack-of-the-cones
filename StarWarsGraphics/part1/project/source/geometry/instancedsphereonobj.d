/// Instanced spheres that sit on top of other objects
module instancedsphereonobj;

import bindbc.opengl;
import std.stdio;
import std.math;
import geometry;
import linear;
import objgeometry;
import texturedobjgeometry;
import instancedtexturedobj;
import error;
import std.random;

// Struct to store instance data
struct InstanceData {
    vec3 position;
    vec3 scale;
    vec4 rotation; // Quaternion rotation
}

/// Geometry that renders spheres on top of other objects
class InstancedSphereOnObjSurface : ISurface {
    GLuint mVBO;         // Vertex buffer
    GLuint mIBO;         // Index buffer
    GLuint mInstanceVBO; // Instance data buffer
    TexturedObjSurface mBaseSurface; // The base sphere object
    InstanceData[] mInstanceData; // Array of instance data
    int mInstanceCount;  // Number of instances
    InstancedTexturedObjSurface mParentObj; // The object the spheres sit on top of
    
    /// Constructor
    this(string objFilename, string mtlFilename, InstancedTexturedObjSurface parentObj) {
        // Load the base sphere object
        mBaseSurface = new TexturedObjSurface(objFilename, mtlFilename);
        mParentObj = parentObj;
        mInstanceCount = parentObj.mInstanceCount;
        
        // Generate instance data based on parent object
        GenerateInstanceData();
        
        // Initialize the instance buffer
        SetupInstanceBuffer();
    }
    
    /// Generate instance data based on parent object positions
    void GenerateInstanceData() {
        mInstanceData = new InstanceData[mInstanceCount];
        
        // Random number generator for slight variations
        auto rnd = Random(42);
        
        // For each cone in the parent object, create a sphere on top
        for (int i = 0; i < mInstanceCount; i++) {
            // Get the position and scale of the parent cone
            vec3 conePosition = mParentObj.mInstanceData[i].position;
            vec3 coneScale = mParentObj.mInstanceData[i].scale;
            
            // Position the sphere directly on top of the cone
            // Account for cone height and slight overlap to look "attached"
            float sphereY = conePosition.y + (coneScale.y * 1.7f); 
            
            // Create instance data for sphere
            mInstanceData[i].position = vec3(conePosition.x, sphereY, conePosition.z);
            
            // Make sphere bigger than cone
            // Width of the cone at the top is less than at base, so multiply by ~2-3x
            float scoopSize = coneScale.x * 2.2f + uniform(-0.02f, 0.02f, rnd); // Slight size variation
            mInstanceData[i].scale = vec3(scoopSize, scoopSize, scoopSize);
            
            // Use the same rotation as the cone
            mInstanceData[i].rotation = mParentObj.mInstanceData[i].rotation;
        }
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
        
        // Calculate buffer size and fill it
        GLfloat[] instanceBuffer;
        foreach (instance; mInstanceData) {
            // Position (vec3)
            instanceBuffer ~= instance.position.x;
            instanceBuffer ~= instance.position.y;
            instanceBuffer ~= instance.position.z;
            
            // Scale (vec3)
            instanceBuffer ~= instance.scale.x;
            instanceBuffer ~= instance.scale.y;
            instanceBuffer ~= instance.scale.z;
            
            // Rotation (vec4 quaternion)
            instanceBuffer ~= instance.rotation.x;
            instanceBuffer ~= instance.rotation.y;
            instanceBuffer ~= instance.rotation.z;
            instanceBuffer ~= instance.rotation.w;
        }
        
        // Upload instance data to GPU
        glBufferData(GL_ARRAY_BUFFER, instanceBuffer.length * GLfloat.sizeof, 
                    instanceBuffer.ptr, GL_STATIC_DRAW);
        
        // Setup instance attributes
        // Position attribute (vec3)
        glEnableVertexAttribArray(3); // Start from 3 to avoid conflicts
        glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 10 * GLfloat.sizeof, cast(void*)0);
        glVertexAttribDivisor(3, 1); // Only increment once per instance
        
        // Scale attribute (vec3)
        glEnableVertexAttribArray(4);
        glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, 10 * GLfloat.sizeof, 
                            cast(void*)(3 * GLfloat.sizeof));
        glVertexAttribDivisor(4, 1);
        
        // Rotation attribute (vec4)
        glEnableVertexAttribArray(5);
        glVertexAttribPointer(5, 4, GL_FLOAT, GL_FALSE, 10 * GLfloat.sizeof, 
                            cast(void*)(6 * GLfloat.sizeof));
        glVertexAttribDivisor(5, 1);
        
        // Unbind
        glBindVertexArray(0);
    }

    /// Get texture paths from base surface
    string GetDiffuseMapPath() {
        return mBaseSurface.GetDiffuseMapPath();
    }
    
    string GetSpecMapPath() {
        return mBaseSurface.GetSpecMapPath();
    }
    
    string GetNormalMapPath() {
        return mBaseSurface.GetNormalMapPath();
    }
    
    /// Render all instances
    override void Render() {
        // Bind VAO
        glBindVertexArray(mVAO);
        
        // Draw instanced
        glDrawElementsInstanced(
            GL_TRIANGLES,
            cast(GLuint)mBaseSurface.mIndexData.length,
            GL_UNSIGNED_INT,
            null,
            mInstanceCount
        );
        
        // Unbind
        glBindVertexArray(0);
    }
}