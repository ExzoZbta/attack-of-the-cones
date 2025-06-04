/// Textured OBJ File Creation
module texturedobjgeometry;

import bindbc.opengl;
import std.stdio;
import geometry;
import error;
import std.file;
import std.string;
import std.conv;
import std.math;
import std.path;
import std.algorithm;

/// Geometry stores all of the vertices, texture coordinates, normals, and indices for a 3D object.
class TexturedObjSurface : ISurface{
    GLuint mVBO;
    GLuint mIBO;
    GLfloat[] mVertexData;
    GLfloat[] mNormalData;
    GLfloat[] mTextureData;
    GLuint[] mIndexData;
    size_t mTriangles;
    
    // Material related paths
    string mMtlFilePath;
    string mDiffuseMapPath;
    string mSpecMapPath;
    string mNormalMapPath;

    /// Geometry data with separate material file
    this(string objFilePath, string mtlFilePath){
        mMtlFilePath = mtlFilePath;
        MakeTexturedOBJ(objFilePath);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndexData.length, GL_UNSIGNED_INT, null);
    }

    // Parse MTL file to get texture map paths
    void ParseMtlFile(string mtlFilePath) {
        try {
            auto lines = readText(mtlFilePath).splitLines();
            string basePath = dirName(mtlFilePath);
            
            foreach(line; lines) {
                auto parts = line.split();
                if(parts.length == 0) continue;
                
                switch(parts[0]) {
                    case "map_Kd": // Diffuse texture map
                        if(parts.length >= 2) {
                            mDiffuseMapPath = buildPath(basePath, parts[1]);
                            writeln("Diffuse map: ", mDiffuseMapPath);
                        }
                        break;
                    
                    case "map_Ks": // Specular texture map
                        if(parts.length >= 2) {
                            mSpecMapPath = buildPath(basePath, parts[1]);
                            writeln("Specular map: ", mSpecMapPath);
                        }
                        break;
                    
                    case "map_Bump": // Normal texture map
                        if(parts.length >= 2) {
                            mNormalMapPath = buildPath(basePath, parts[1]);
                            writeln("Normal map: ", mNormalMapPath);
                        }
                        break;
                    
                    default:
                        break;
                }
            }
        } catch (Exception e) {
            writeln("Error parsing MTL file: ", e.msg);
            throw e;
        }
    }

    void SaveDebugOBJ(string outputFilename, GLfloat[] vertexData, GLuint[] indexData) {
        // Create the debug file
        try {
            writeln("Attempting to save debug OBJ to: ", outputFilename);
            auto f = File(outputFilename, "w");
            
            // Comment header 
            f.writeln("# Debug OBJ file generated from loaded data");
            f.writefln("# Contains %d vertices and %d triangles", vertexData.length / 8, indexData.length / 3);
            
            // First write all vertices (v)
            for(size_t i = 0; i < vertexData.length; i += 8) {
                if(i + 2 < vertexData.length) {
                    f.writefln("v %f %f %f", 
                            vertexData[i], 
                            vertexData[i+1], 
                            vertexData[i+2]);
                }
            }
            
            // Write texture coordinates (vt)
            for(size_t i = 0; i < vertexData.length; i += 8) {
                if(i + 7 < vertexData.length) {
                    f.writefln("vt %f %f", 
                            vertexData[i+6], 
                            vertexData[i+7]);
                }
            }
            
            // Write normals (vn)
            for(size_t i = 0; i < vertexData.length; i += 8) {
                if(i + 5 < vertexData.length) {
                    f.writefln("vn %f %f %f", 
                            vertexData[i+3], 
                            vertexData[i+4], 
                            vertexData[i+5]);
                }
            }
            
            // Write faces
            for(size_t i = 0; i < indexData.length; i += 3) {
                if(i + 2 < indexData.length) {
                    // OBJ indices are 1-based
                    f.writefln("f %d/%d/%d %d/%d/%d %d/%d/%d", 
                            indexData[i]+1, indexData[i]+1, indexData[i]+1,
                            indexData[i+1]+1, indexData[i+1]+1, indexData[i+1]+1,
                            indexData[i+2]+1, indexData[i+2]+1, indexData[i+2]+1);
                }
            }
            
            f.close();
            writeln("Debug OBJ saved successfully to: ", outputFilename);
            
            // Verify the file
            if(std.file.exists(outputFilename)) {
                writeln("Confirmed: Debug file exists");
            } else {
                writeln("ERROR: Debug file was not created!");
            }
        } catch(Exception e) {
            writeln("ERROR saving debug OBJ: ", e.msg);
        }
    }

    // Create a textured OBJ
    void MakeTexturedOBJ(string filepath){
        writeln("Loading Textured OBJ file: ", filepath);
        
        // Parse the material file if provided
        if(mMtlFilePath !is null && mMtlFilePath.length > 0) {
            ParseMtlFile(mMtlFilePath);
        }

        // Parse OBJ file
        try {
            auto lines = readText(filepath).splitLines();
            
            // Temporary storage for the raw vertices, texture coordinates, and normals
            GLfloat[][] verticesRaw;
            GLfloat[][] texCoordsRaw;
            GLfloat[][] normalsRaw;
            
            // Structure to store a unique vertex (position, texture, normal indices)
            struct Vertex {
                int posIndex, texIndex, normIndex;
                
                string toString() const {
                    import std.format;
                    return format("%d/%d/%d", posIndex, texIndex, normIndex);
                }
            }
            
            // Map from vertex string representation to index in final vertex array
            int[string] vertexIndices;
            
            // Final vertex data (interleaved: position, normal, texcoord)
            GLfloat[] finalVertices;
            GLuint[] finalIndices;
            
            // First pass: read all raw vertex data
            foreach(line; lines) {
                auto parts = line.split();
                if(parts.length == 0) continue;
                
                switch(parts[0]) {
                    case "v":  // Vertex position
                        if(parts.length >= 4) {
                            verticesRaw ~= [
                                to!float(parts[1]),
                                to!float(parts[2]),
                                to!float(parts[3])
                            ];
                        }
                        break;
                    
                    case "vt": // Texture coordinate
                        if(parts.length >= 3) {
                            // Store raw texture coordinates
                            texCoordsRaw ~= [
                                to!float(parts[1]),
                                to!float(parts[2])
                            ];
                            // Debug: texture coordinates
                            if(texCoordsRaw.length <= 5) {
                                writefln("Texture coord %d: (%f, %f)", 
                                    texCoordsRaw.length, 
                                    to!float(parts[1]), 
                                    to!float(parts[2]));
                            }
                        }
                        break;
                        
                    case "vn": // Vertex normal
                        if(parts.length >= 4) {
                            normalsRaw ~= [
                                to!float(parts[1]),
                                to!float(parts[2]),
                                to!float(parts[3])
                            ];
                        }
                        break;
                    
                    default:
                        break;
                }
            }
            
            writeln("Raw vertex data: ", verticesRaw.length, " positions, ", 
                    texCoordsRaw.length, " texture coordinates, ", 
                    normalsRaw.length, " normals");
            
            // Second pass: process faces
            foreach(line; lines) {
                auto parts = line.split();
                if(parts.length == 0 || parts[0] != "f") continue;
                
                // Store indices for this face
                Vertex[] faceVertices;
                
                // Process each vertex of the face
                for(int i = 1; i < parts.length; i++) {
                    auto indices = parts[i].split("/");
                    
                    Vertex v;
                    v.posIndex = indices.length > 0 && indices[0].length > 0 ? 
                                to!int(indices[0]) - 1 : -1;
                    v.texIndex = indices.length > 1 && indices[1].length > 0 ? 
                                to!int(indices[1]) - 1 : -1;
                    v.normIndex = indices.length > 2 && indices[2].length > 0 ? 
                                to!int(indices[2]) - 1 : -1;
                    
                    // Convert to string for map lookup
                    string key = v.toString();
                    
                    // Add vertex combination if not already seen
                    if(key !in vertexIndices) {
                        // Position
                        if(v.posIndex >= 0 && v.posIndex < verticesRaw.length) {
                            // Apply coordinate system transformation
                            finalVertices ~= -verticesRaw[v.posIndex][0];
                            finalVertices ~= verticesRaw[v.posIndex][1];
                            finalVertices ~= verticesRaw[v.posIndex][2]; 
                        } else {
                            finalVertices ~= 0.0f;
                            finalVertices ~= 0.0f;
                            finalVertices ~= 0.0f;
                        }
                        
                        // Normal
                        if(v.normIndex >= 0 && v.normIndex < normalsRaw.length) {
                            // Also flip normal Z component
                            finalVertices ~= -normalsRaw[v.normIndex][0];
                            finalVertices ~= normalsRaw[v.normIndex][1];
                            finalVertices ~= normalsRaw[v.normIndex][2]; 
                        } else {
                            finalVertices ~= 0.0f;
                            finalVertices ~= 1.0f;
                            finalVertices ~= 0.0f;
                        }

                        if(v.texIndex >= 0 && v.texIndex < texCoordsRaw.length) {
                            finalVertices ~= 1.0 - texCoordsRaw[v.texIndex][0]; // U coordinate
                            finalVertices ~= texCoordsRaw[v.texIndex][1]; // V coordinate
                        } else {
                            finalVertices ~= 0.0f;
                            finalVertices ~= 0.0f;
                        }
                                                
                        // Store the index
                        vertexIndices[key] = cast(int)(vertexIndices.length);
                    }
                    
                    faceVertices ~= v;
                }
                
                // Triangulate the face
                for(int i = 1; i < faceVertices.length - 1; i++) {
                    finalIndices ~= cast(GLuint)vertexIndices[faceVertices[0].toString()];
                    finalIndices ~= cast(GLuint)vertexIndices[faceVertices[i].toString()];
                    finalIndices ~= cast(GLuint)vertexIndices[faceVertices[i+1].toString()];
                }
            }
            
            // Store the processed data
            mVertexData = finalVertices;
            mIndexData = finalIndices;
            
            writeln("Processed ", vertexIndices.length, " unique vertices and ", 
                    finalIndices.length / 3, " triangles");

            writeln("Vertex data: ", mVertexData.length, " floats = ", 
                    mVertexData.length * GLfloat.sizeof, " bytes");
            writeln("Index data: ", mIndexData.length, " indices = ", 
                    mIndexData.length * GLuint.sizeof, " bytes");

            // Verify buffer sizes before creating OpenGL objects
            if(mVertexData.length == 0 || mIndexData.length == 0) {
                writeln("ERROR: Empty vertex or index data!");
                throw new Exception("Failed to load model data");
            }
            
            // Generate OpenGL buffers
            glGenVertexArrays(1, &mVAO);
            glBindVertexArray(mVAO);
            
            // Vertex buffer
            glGenBuffers(1, &mVBO);
            glBindBuffer(GL_ARRAY_BUFFER, mVBO);
            void* vertexDataPtr = mVertexData.ptr;
            writeln("Vertex data pointer: ", cast(void*)vertexDataPtr);

            glBufferData(GL_ARRAY_BUFFER, 
                        mVertexData.length * GLfloat.sizeof, 
                        mVertexData.ptr, 
                        GL_STATIC_DRAW);
            
            // Check for OpenGL errors
            GLenum err = glGetError();
            if(err != GL_NO_ERROR) {
                writeln("OpenGL Error after vertex buffer creation: ", err);
            }

            // Index buffer
            glGenBuffers(1, &mIBO);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);

            void* indexDataPtr = mIndexData.ptr;
            writeln("Index data pointer: ", cast(void*)indexDataPtr);

            glBufferData(GL_ELEMENT_ARRAY_BUFFER, 
                        mIndexData.length * GLuint.sizeof, 
                        indexDataPtr, 
                        GL_STATIC_DRAW);

            err = glGetError();
            if(err != GL_NO_ERROR) {
                writeln("OpenGL Error after index buffer creation: ", err);
            }
            
            // Set up vertex attributes (position, normal, texture)
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, 
                                cast(void*)0);
            
            glEnableVertexAttribArray(1);
            glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, 
                                cast(void*)(3 * GLfloat.sizeof));
            
            glEnableVertexAttribArray(2);
            glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, 
                                cast(void*)(6 * GLfloat.sizeof));

            err = glGetError();
            if(err != GL_NO_ERROR) {
                writeln("OpenGL Error after setting up vertex attributes: ", err);
            }
            
            // Unbind
            glBindVertexArray(0);
            glDisableVertexAttribArray(0);
            glDisableVertexAttribArray(1);
            glDisableVertexAttribArray(2);
            
            string debugFilePath = "./debug_output.obj";
            SaveDebugOBJ(debugFilePath, mVertexData, mIndexData);

            // Check if the file was created
            if(std.file.exists(debugFilePath)) {
                writeln("Debug file created at: ", debugFilePath);
            } else {
                writeln("WARNING: Failed to create debug file at: ", debugFilePath);
                
                // Try an alternative location
                debugFilePath = "/tmp/debug_output.obj";
                SaveDebugOBJ(debugFilePath, mVertexData, mIndexData);
                
                if(std.file.exists(debugFilePath)) {
                    writeln("Debug file created at alternative location: ", debugFilePath);
                } else {
                    writeln("ERROR: Could not create debug file in either location");
                }
            }
        
        } catch (Exception e) {
            writeln("Error loading textured OBJ file: ", e.msg);
            throw e;
        }
    }

    // Getter methods for texture paths
    string GetDiffuseMapPath() { return mDiffuseMapPath; }
    string GetSpecMapPath() { return mSpecMapPath; }
    string GetNormalMapPath() { return mNormalMapPath; }
}