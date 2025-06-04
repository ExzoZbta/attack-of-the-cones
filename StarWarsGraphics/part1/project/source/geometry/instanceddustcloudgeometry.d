/// Dustcloud Geometry Implementation
module instanceddustcloudgeometry;

import bindbc.opengl;
import std.stdio;
import std.algorithm;
import std.math;
import std.random;
import geometry;
import linear;

// Creates a 3D volume of points to represent a dustcloud with instanced rendering
class InstancedDustCloudGeometry : ISurface {
    GLuint mVBO;          // Vertex buffer for the cloud model
    GLuint mInstanceVBO;  // Instance data buffer
    size_t mPointCount;   // Points per instance
    size_t mInstanceCount; // Number of instances
    float mCloudScale;
    bool mIsPervasiveDust;

    /// Constructor for instanced dust cloud geometry
    this(int pointCount = 10000, float radius = 50.0f, int instanceCount = 10) {
        writeln("Creating instanced dust cloud with ", pointCount, " points per instance, radius ", 
                radius, " and ", instanceCount, " instances");
        
        // Generate a random scale factor for cloud variations
        auto rnd = Random(42);
        mCloudScale = uniform(0.8f, 1.2f, rnd);
        mIsPervasiveDust = false;
        mInstanceCount = instanceCount;
        
        // Generate cloud model with fewer points per instance
        GenerateCloudGeometry(pointCount, radius);
        
        // Generate instance data
        GenerateInstanceData(instanceCount, radius * 3.0f);
    }

    /// Special constructor for creating ambient dust that fills the scene
    this(int pointCount, float radius, int instanceCount, bool isPervasiveDust) {
        writeln("Creating instanced pervasive dust with ", pointCount, " points per instance, radius ", 
                radius, " and ", instanceCount, " instances");
        
        mCloudScale = 1.0f;
        mIsPervasiveDust = isPervasiveDust;
        mInstanceCount = instanceCount;
        
        // Generate dust with fewer points per instance
        GeneratePervasiveDustGeometry(pointCount, radius);
        
        // Generate instance data for wider distribution
        GenerateInstanceData(instanceCount, radius * 5.0f, true);
    }

    /// Generate the cloud geometry as a 3D volume
    void GenerateCloudGeometry(int pointCount, float radius) {
        // We'll create a set of points distributed within a spherical volume
        // Each point will have position (xyz), normal (xyz), and texture coordinates (st)
        GLfloat[] vertices;
        vertices.length = pointCount * 8; // 3 for pos, 3 for normal, 2 for texcoord

        // Generate random points within a spherical volume
        auto rnd = Random(42); // Fixed seed for reproducibility
        
        // Create several cluster centers to form chunky cloud formations
        const int numClusters = 5 + cast(int)(radius / 10.0f);  // Fewer clusters per instance
        vec3[] clusterCenters;
        float[] clusterSizes;  // Different sizes for each cluster
        
        // Generate random cluster centers within the volume
        for (int i = 0; i < numClusters; i++) {
            float cx, cy, cz;
            float dist;
            
            // Generate cluster centers with wider dispersion
            do {
                cx = uniform(-1.2f, 1.2f, rnd);
                cy = uniform(-1.0f, 1.0f, rnd);
                cz = uniform(-1.2f, 1.2f, rnd);
                dist = sqrt(cx*cx + cy*cy + cz*cz);
            } while (dist > 1.4f);
            
            clusterCenters ~= vec3(cx, cy, cz);
            
            // Varying cluster sizes create more natural cloud formations
            clusterSizes ~= uniform(0.1f, 0.4f, rnd);
        }
        
        // Distribute points among clusters
        for (int i = 0; i < pointCount; i++) {
            float x, y, z;
            
            // Select which cluster this point belongs to
            int clusterIndex = cast(int)(uniform(0.0f, cast(float)numClusters, rnd));
            if (clusterIndex >= numClusters) clusterIndex = numClusters - 1;
            
            vec3 clusterCenter = clusterCenters[clusterIndex];
            float clusterSize = clusterSizes[clusterIndex];
            
            // Generate point near the cluster center with gaussian-like distribution
            float angle1 = uniform(0.0f, 2.0f * PI, rnd);
            float angle2 = uniform(0.0f, 2.0f * PI, rnd);
            
            float r = pow(uniform(0.0f, 1.0f, rnd), 0.3f) * clusterSize;
            
            // Spherical coordinates for cluster point distribution
            x = clusterCenter.x + r * sin(angle1) * cos(angle2);
            y = clusterCenter.y + r * sin(angle1) * sin(angle2);
            z = clusterCenter.z + r * cos(angle1);
            
            // Add some noise to break up perfect spherical clusters
            x += uniform(-0.1f, 0.1f, rnd);
            y += uniform(-0.1f, 0.1f, rnd);
            z += uniform(-0.1f, 0.1f, rnd);
            
            // Scale to desired radius
            x *= radius;
            y *= radius;
            z *= radius;

            // Calculate normal for lighting
            float dist = sqrt(x*x + y*y + z*z);
            float nx = x / (radius * max(dist, 0.001f));
            float ny = y / (radius * max(dist, 0.001f));
            float nz = z / (radius * max(dist, 0.001f));

            // Generate texture coordinates based on position
            float s = (x / radius + 1.0f) * 0.5f * mCloudScale;
            float t = (z / radius + 1.0f) * 0.5f * mCloudScale;

            // Set the vertex data
            int baseIdx = i * 8;
            vertices[baseIdx + 0] = x;
            vertices[baseIdx + 1] = y;
            vertices[baseIdx + 2] = z;
            vertices[baseIdx + 3] = nx;
            vertices[baseIdx + 4] = ny;
            vertices[baseIdx + 5] = nz;
            vertices[baseIdx + 6] = s;
            vertices[baseIdx + 7] = t;
        }

        mPointCount = pointCount;
        writeln("InstancedDustCloud: Created ", mPointCount, " points for each instance");

        // Create and bind VAO
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);

        // Create and bind VBO for vertex data
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);

        // Set up vertex attributes
        SetVertexAttributes!VertexFormat3F3F2F();

        // Unbind VAO to prevent accidental changes
        glBindVertexArray(0);
    }
    
    /// Generate pervasive dust with fewer points per instance
    void GeneratePervasiveDustGeometry(int pointCount, float radius) {
        // Create vertices array
        GLfloat[] vertices;
        vertices.length = pointCount * 8; // 3 for pos, 3 for normal, 2 for texcoord
        
        auto rnd = Random(24); // Different seed for variation
        
        // Create dust particles but with fewer points per instance
        for (int i = 0; i < pointCount; i++) {
            float x, y, z;
            
            // Simplified distribution since we'll rely on instancing for variety
            if (i % 3 == 0) {
                // Uniform distribution throughout a volume
                x = uniform(-radius, radius, rnd);
                y = uniform(-radius * 0.5f, radius * 0.5f, rnd);
                z = uniform(-radius, radius, rnd);
            } 
            else if (i % 3 == 1) {
                // Concentrated along horizontal plane
                x = uniform(-radius, radius, rnd);
                y = uniform(-radius * 0.2f, radius * 0.2f, rnd);
                z = uniform(-radius, radius, rnd);
            }
            else {
                // Peripheral distribution
                float angle = uniform(0.0f, 2.0f * PI, rnd);
                float dist = uniform(radius * 0.5f, radius, rnd);
                x = dist * cos(angle);
                y = uniform(-radius * 0.4f, radius * 0.4f, rnd);
                z = dist * sin(angle);
            }
            
            // Calculate normal (pointing outward from origin)
            float dist = sqrt(x*x + y*y + z*z);
            float nx = x / (radius * max(dist, 0.001f));
            float ny = y / (radius * max(dist, 0.001f));
            float nz = z / (radius * max(dist, 0.001f));
            
            // Generate texture coordinates
            float s = (x / radius + 1.0f) * 0.5f;
            float t = (z / radius + 1.0f) * 0.5f;
            
            // Set vertex data
            int baseIdx = i * 8;
            vertices[baseIdx + 0] = x;
            vertices[baseIdx + 1] = y;
            vertices[baseIdx + 2] = z;
            vertices[baseIdx + 3] = nx;
            vertices[baseIdx + 4] = ny;
            vertices[baseIdx + 5] = nz;
            vertices[baseIdx + 6] = s;
            vertices[baseIdx + 7] = t;
        }
        
        mPointCount = pointCount;
        writeln("InstancedPervasiveDust: Created ", mPointCount, " dust particles for each instance");
        
        // Create and bind VAO
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);

        // Create and bind VBO for vertex data
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);

        // Set up vertex attributes
        SetVertexAttributes!VertexFormat3F3F2F();

        // Unbind VAO
        glBindVertexArray(0);
    }

    /// Generate instance data for multiple cloud instances
    void GenerateInstanceData(int instanceCount, float distributionRadius, bool isPervasive = false) {
        // For each instance, we need:
        // - Position offset (vec3)
        // - Scale factor (vec3)
        // - Rotation as quaternion (vec4)
        GLfloat[] instanceData;
        instanceData.length = instanceCount * 10; // 3 for pos, 3 for scale, 4 for rotation
        
        auto rnd = Random(100); // Different seed for instance variations
        
        // Generate random instance data
        for (int i = 0; i < instanceCount; i++) {
            float x, y, z; // Position
            float sx, sy, sz; // Scale
            float qx, qy, qz, qw; // Rotation quaternion
            
            if (isPervasive) {
                // Position widely distributed for pervasive dust
                float angle = (2.0f * PI * i) / instanceCount + uniform(-0.5f, 0.5f, rnd);
                float elevation = uniform(-1.0f, 1.0f, rnd);
                float distance = uniform(0.0f, distributionRadius, rnd);
                
                // Spherical distribution
                x = distance * cos(angle) * sqrt(1.0f - elevation * elevation);
                y = distance * elevation;
                z = distance * sin(angle) * sqrt(1.0f - elevation * elevation);
                
                // Random scaling for variation
                sx = uniform(0.8f, 1.5f, rnd);
                sy = uniform(0.5f, 2.0f, rnd);
                sz = uniform(0.8f, 1.5f, rnd);
                
                // Smaller scale variations for ambient dust
                sx *= 0.8f;
                sy *= 0.8f;
                sz *= 0.8f;
            } 
            else {
                // For regular dust clouds, position in a more structured pattern
                if (i == 0) {
                    // First instance centered at origin
                    x = 0.0f;
                    y = 0.0f;
                    z = 0.0f;
                } 
                else {
                    // Distribute others in a spherical pattern
                    float angle = (2.0f * PI * (i-1)) / (instanceCount-1) + uniform(-0.2f, 0.2f, rnd);
                    float elevation = uniform(-0.8f, 0.8f, rnd);
                    float distance = uniform(distributionRadius * 0.2f, distributionRadius, rnd);
                    
                    x = distance * cos(angle) * sqrt(1.0f - elevation * elevation);
                    y = distance * elevation * 0.6f; // Compress vertically
                    z = distance * sin(angle) * sqrt(1.0f - elevation * elevation);
                }
                
                // Scales for regular dust clouds
                sx = uniform(0.8f, 2.0f, rnd);
                sy = uniform(0.7f, 1.5f, rnd);
                sz = uniform(0.8f, 2.0f, rnd);
            }
            
            // Generate a random rotation quaternion
            // First create a random axis of rotation
            float axis_x = uniform(-1.0f, 1.0f, rnd);
            float axis_y = uniform(-1.0f, 1.0f, rnd);
            float axis_z = uniform(-1.0f, 1.0f, rnd);
            float axis_len = sqrt(axis_x*axis_x + axis_y*axis_y + axis_z*axis_z);
            
            if (axis_len > 0.0001f) {
                axis_x /= axis_len;
                axis_y /= axis_len;
                axis_z /= axis_len;
            }
            
            // Generate random rotation angle and create quaternion
            float angle = uniform(0.0f, 2.0f * PI, rnd);
            float sin_half = sin(angle * 0.5f);
            float cos_half = cos(angle * 0.5f);
            
            qx = axis_x * sin_half;
            qy = axis_y * sin_half;
            qz = axis_z * sin_half;
            qw = cos_half;
            
            // Store instance data
            int baseIdx = i * 10;
            instanceData[baseIdx + 0] = x;
            instanceData[baseIdx + 1] = y;
            instanceData[baseIdx + 2] = z;
            instanceData[baseIdx + 3] = sx;
            instanceData[baseIdx + 4] = sy;
            instanceData[baseIdx + 5] = sz;
            instanceData[baseIdx + 6] = qx;
            instanceData[baseIdx + 7] = qy;
            instanceData[baseIdx + 8] = qz;
            instanceData[baseIdx + 9] = qw;
        }
        
        // Create VBO for instance data
        glBindVertexArray(mVAO);
        
        glGenBuffers(1, &mInstanceVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mInstanceVBO);
        glBufferData(GL_ARRAY_BUFFER, instanceData.length * GLfloat.sizeof, instanceData.ptr, GL_STATIC_DRAW);
        
        // Position (vec3)
        glEnableVertexAttribArray(3);
        glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 10 * GLfloat.sizeof, cast(void*)(0));
        glVertexAttribDivisor(3, 1); // Set instance data rate
        
        // Scale (vec3)
        glEnableVertexAttribArray(4);
        glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, 10 * GLfloat.sizeof, cast(void*)(3 * GLfloat.sizeof));
        glVertexAttribDivisor(4, 1); // Set instance data rate
        
        // Rotation (vec4 quaternion)
        glEnableVertexAttribArray(5);
        glVertexAttribPointer(5, 4, GL_FLOAT, GL_FALSE, 10 * GLfloat.sizeof, cast(void*)(6 * GLfloat.sizeof));
        glVertexAttribDivisor(5, 1); // Set instance data rate
        
        glBindVertexArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        writeln("Created ", instanceCount, " instance data entries");
    }
    
    /// Render all dust cloud instances
    override void Render() {
        // Save current OpenGL state
        GLboolean depthTest;
        glGetBooleanv(GL_DEPTH_TEST, &depthTest);
        GLboolean blend;
        glGetBooleanv(GL_BLEND, &blend);
        GLint blendSrc, blendDst;
        glGetIntegerv(GL_BLEND_SRC_ALPHA, &blendSrc);
        glGetIntegerv(GL_BLEND_DST_ALPHA, &blendDst);
        
        glBindVertexArray(mVAO);
        
        // Enable point size adjustment
        glEnable(GL_PROGRAM_POINT_SIZE);
        if (mIsPervasiveDust) {
            // Smaller points for pervasive dust, but more numerous
            glPointSize(25.0f);
            // Additive blending for atmospheric effect
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        } else {
            // Large points for chunky cloud formations
            glPointSize(90.0f);
            // Standard alpha blending for chunky clouds
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        
        // Always draw points regardless of depth test
        glDisable(GL_DEPTH_TEST);
        glDepthMask(GL_FALSE);
        
        // Draw all instances
        glDrawArraysInstanced(GL_POINTS, 0, cast(int)mPointCount, cast(int)mInstanceCount);
        
        // Restore previous OpenGL state
        if (depthTest) glEnable(GL_DEPTH_TEST);
        else glDisable(GL_DEPTH_TEST);
        glDepthMask(GL_TRUE);
        
        if (blend) glEnable(GL_BLEND);
        else glDisable(GL_BLEND);
        
        glBlendFunc(blendSrc, blendDst);
        glDisable(GL_PROGRAM_POINT_SIZE);
        glBindVertexArray(0);
    }
}