/// OBJ File Creation
module objgeometry;

import bindbc.opengl;
import std.stdio;
import geometry;
import error;
import std.file;
import std.string;
import std.conv;
import std.math;

/// Geometry stores all of the vertices and/or indices for a 3D object.
/// Geometry also has the responsibility of setting up the 'attributes'
class SurfaceOBJ : ISurface{
    GLuint mVBO;
    GLuint mIBO;
    GLfloat[] mVertexData;
	GLfloat[] mNormalData;
	GLfloat[] mTextureData;
    GLuint[] mIndexData;
    size_t mTriangles;

    /// Geometry data
    this(string filename){
        MakeOBJ(filename);
    }

    /// Render geometry
    override void Render(){
        // Bind to geometry to draw
        glBindVertexArray(mVAO);
        // Call draw call
        glDrawElements(GL_TRIANGLES,cast(GLuint)mIndexData.length,GL_UNSIGNED_INT,null);
    }

    void MakeOBJ(string filepath){

		// TODO 
		// You can erase all of this code, or otherwise add the parsing of your OBJ
		// file here.
        writeln("Loading OBJ file: ", filepath);

         // Parse OBJ file
        try {
            auto lines = readText(filepath).splitLines();
            
            // Temporary storage for vertices and normals from the file
            GLfloat[][] vertices;
            GLfloat[][] normals;
            
            foreach(line; lines) {
                auto parts = line.split();
                if(parts.length == 0) continue;
                
                switch(parts[0]) {
                    case "v":  // Vertex
                        if(parts.length >= 4) {
                            vertices ~= [
                                to!float(parts[1]),
                                to!float(parts[2]),
                                to!float(parts[3])
                            ];
                        }
                        break;
                        
                    case "vn": // Vertex normal
                        if(parts.length >= 4) {
                            normals ~= [
                                to!float(parts[1]),
                                to!float(parts[2]),
                                to!float(parts[3])
                            ];
                        }
                        break;
                        
                    case "f": // Face
                        if(parts.length >= 4) { 
                            for(int i = 1; i < parts.length; i++) {
                                auto vertexData = parts[i].split("/");
                                if(vertexData.length >= 1) {

                                    int vertexIndex = to!int(vertexData[0]) - 1;
                                    
                                    // Add vertex data
                                    if(vertexIndex >= 0 && vertexIndex < vertices.length) {
                                        mVertexData ~= vertices[vertexIndex];
                                    }
                                    
                                    // Add normal data if available
                                    if(vertexData.length >= 3 && vertexData[2].length > 0) {
                                        int normalIndex = to!int(vertexData[2]) - 1;
                                        if(normalIndex >= 0 && normalIndex < normals.length) {
                                            mNormalData ~= normals[normalIndex];
                                        }
                                    }
                                }
                            }
                            
                            // Create indices for triangulation
                            int baseIndex = cast(int)(mIndexData.length > 0 ? mIndexData[$-1] + 1 : 0);
                            for(int i = 0; i < parts.length - 3; i++) {
                                mIndexData ~= baseIndex;
                                mIndexData ~= baseIndex + i + 1;
                                mIndexData ~= baseIndex + i + 2;
                            }
                        }
                        break;
                    
                    default:
                        break;
                }
            }

            // If no normals were loaded, generate simple ones
            if(mNormalData.length == 0) {
                writeln("No normals found in OBJ file, generating simple normals");
                for(size_t i = 0; i < mVertexData.length; i += 9) {
                    // For each triangle, calculate a normal
                    if(i + 8 < mVertexData.length) {
                        float x1 = mVertexData[i];
                        float y1 = mVertexData[i+1];
                        float z1 = mVertexData[i+2];
                        
                        float x2 = mVertexData[i+3];
                        float y2 = mVertexData[i+4];
                        float z2 = mVertexData[i+5];
                        
                        float x3 = mVertexData[i+6];
                        float y3 = mVertexData[i+7];
                        float z3 = mVertexData[i+8];
                        
                        // Calculate normal
                        float ux = x2 - x1;
                        float uy = y2 - y1;
                        float uz = z2 - z1;
                        
                        float vx = x3 - x1;
                        float vy = y3 - y1;
                        float vz = z3 - z1;
                        
                        float nx = (uy * vz) - (uz * vy);
                        float ny = (uz * vx) - (ux * vz);
                        float nz = (ux * vy) - (uy * vx);
                        
                        // Normalize
                        float length = sqrt(nx*nx + ny*ny + nz*nz);
                        if(length > 0) {
                            nx /= length;
                            ny /= length;
                            nz /= length;
                        }
                        
                        // Add the same normal for all 3 vertices
                        mNormalData ~= nx;
                        mNormalData ~= ny;
                        mNormalData ~= nz;
                        
                        mNormalData ~= nx;
                        mNormalData ~= ny;
                        mNormalData ~= nz;
                        
                        mNormalData ~= nx;
                        mNormalData ~= ny;
                        mNormalData ~= nz;
                    }
                }
            }
            
            writeln("Loaded OBJ with ", mVertexData.length/3, " vertices and ", mIndexData.length/3, " triangles");
        } catch (Exception e) {
            writeln("Error loading OBJ file: ", e.msg);
            throw e;
        }
		
        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) 
        // that we want to work withn.
        glBindVertexArray(mVAO);

        // Index Buffer Object (IBO)
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mIndexData.length* GLuint.sizeof, mIndexData.ptr, GL_STATIC_DRAW);

        // Vertex Buffer Object (VBO) creation
        GLfloat[] allData;
        for(size_t i=0; i < mVertexData.length; i+=3){
            allData ~= mVertexData[i];
            allData ~= mVertexData[i+1];
            allData ~= mVertexData[i+2];
            // Add normals if available
            if(i < mNormalData.length) {
                allData ~= mNormalData[i];
                allData ~= mNormalData[i+1];
                allData ~= mNormalData[i+2];
            } else {
                // Default normal if none available
                allData ~= 0.0f;
                allData ~= 1.0f;
                allData ~= 0.0f;
            }
        }

        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, allData.length* VertexFormat3F3F.sizeof, allData.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F3F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);
        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F3F();
    }
}

