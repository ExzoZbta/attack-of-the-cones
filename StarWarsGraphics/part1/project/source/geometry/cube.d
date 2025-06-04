module geometry.cube;

import bindbc.opengl;
import std.stdio;
import geometry;

/// Cube 
class SurfaceCube : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    
    this() {
        MakeCube();
    }
    
    override void Render() {
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, null);
    }
    
    void MakeCube() {
        // Cube vertices
        GLfloat[] vertices = [
            // Front face
            -0.5f, -0.5f,  0.5f,  0.0f,  0.0f,  1.0f, // Bottom-left
             0.5f, -0.5f,  0.5f,  0.0f,  0.0f,  1.0f, // Bottom-right
             0.5f,  0.5f,  0.5f,  0.0f,  0.0f,  1.0f, // Top-right
            -0.5f,  0.5f,  0.5f,  0.0f,  0.0f,  1.0f, // Top-left
            
            // Back face
            -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f, // Bottom-left
             0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f, // Bottom-right
             0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f, // Top-right
            -0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f, // Top-left
            
            // Left face
            -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f, // Bottom-left
            -0.5f, -0.5f,  0.5f, -1.0f,  0.0f,  0.0f, // Bottom-right
            -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f, // Top-right
            -0.5f,  0.5f, -0.5f, -1.0f,  0.0f,  0.0f, // Top-left
            
            // Right face
             0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f, // Bottom-left
             0.5f, -0.5f,  0.5f,  1.0f,  0.0f,  0.0f, // Bottom-right
             0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f, // Top-right
             0.5f,  0.5f, -0.5f,  1.0f,  0.0f,  0.0f, // Top-left
            
            // Bottom face
            -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f, // Bottom-left
             0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f, // Bottom-right
             0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f, // Top-right
            -0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f, // Top-left
            
            // Top face
            -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f, // Bottom-left
             0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f, // Bottom-right
             0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f, // Top-right
            -0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f  // Top-left
        ];
        
        // Cube indices
        GLuint[] indices = [
            // Front face
            0, 1, 2, 2, 3, 0,
            // Back face
            4, 5, 6, 6, 7, 4,
            // Left face
            8, 9, 10, 10, 11, 8,
            // Right face
            12, 13, 14, 14, 15, 12,
            // Bottom face
            16, 17, 18, 18, 19, 16,
            // Top face
            20, 21, 22, 22, 23, 20
        ];
        
        // VAO
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);
        
        // VBO
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);
        
        // IBO
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STATIC_DRAW);
        
        SetVertexAttributes!VertexFormat3F3F();
        
        // Unbind VAO
        glBindVertexArray(0);
        DisableVertexAttributes!VertexFormat3F3F();
    }
}