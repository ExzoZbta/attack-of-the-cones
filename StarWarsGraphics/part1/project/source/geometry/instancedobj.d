// ArchitPSET8/part1/project/source/geometry/instancedobj.d
/// Instanced OBJ rendering
module instancedobj;

import bindbc.opengl;
import std.stdio;
import geometry;
import linear;
import objgeometry;
import error;
import std.random;
import std.math;

// Struct to store instance data
struct InstanceData {
    vec3 position;
    vec3 scale;
    vec4 rotation; // Quaternion rotation
}

/// Geometry that renders many instances of the same object
class InstancedObjSurface : ISurface {
    GLuint mVBO;      // Vertex buffer
    GLuint mIBO;      // Index buffer
    GLuint mInstanceVBO; // Instance data buffer
    SurfaceOBJ mBaseSurface; // The base object to be instanced
    InstanceData[] mInstanceData; // Array of instance data
    int mInstanceCount; // Number of instances
    bool mUsesModelMatrix = false; // Flag to indicate if this surface uses a model matrix

    
    /// Constructor
    this(string objFilename, int instanceCount) {
        // Load the base object
        mBaseSurface = new SurfaceOBJ(objFilename);
        mInstanceCount = instanceCount;
        
        // Generate random instance data
        GenerateInstanceData();
        
        // Initialize the instance buffer
        SetupInstanceBuffer();
    }
    
    /// Generate random instance data
    void GenerateInstanceData() {
        mInstanceData = new InstanceData[mInstanceCount];
        
        // Random number generator
        auto rnd = Random(42); // Deterministic seed
        
        // Generate instances in a grid pattern
        int gridSize = cast(int)sqrt(cast(real)mInstanceCount);
        float spacing = 0.5f;
        
        for (int i = 0; i < mInstanceCount; i++) {
            // Calculate grid position
            int row = i / gridSize;
            int col = i % gridSize;
            
            // Calculate position with some randomness
            float x = (col - gridSize/2) * spacing + uniform(-0.1f, 0.1f, rnd);
            float z = (row - gridSize/2) * spacing + uniform(-0.1f, 0.1f, rnd);
            
            // Create instance data
            mInstanceData[i].position = vec3(x, -1.0f, z); // Position below main object
            mInstanceData[i].scale = vec3(0.1f, 0.2f, 0.1f); // Small cones
            
            // Random rotation around Y axis
            float angle = uniform(0.0f, 2.0f * 3.14159f, rnd);
            mInstanceData[i].rotation = vec4(0.0f, sin(angle/2.0f), 0.0f, cos(angle/2.0f)); // Quaternion for Y rotation
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
        glEnableVertexAttribArray(3);
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