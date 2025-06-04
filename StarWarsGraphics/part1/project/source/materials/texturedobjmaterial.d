// A material for textured OBJ models
module texturedobjmaterial;

import pipeline, materials, texture;
import bindbc.opengl;
import std.stdio;
import texturedobjgeometry;
import std.file;
import image;

/// Represents a material for textured OBJ models
class TexturedObjMaterial : IMaterial{

    private bool mDebugPrinted = false;
    private static bool sGlobalDebugEnabled = true;

    Texture mDiffuseMap;
    Texture mSpecularMap;
    Texture mNormalMap;
    bool mHasDiffuseMap = false;
    bool mHasSpecularMap = false;
    bool mHasNormalMap = false;

    /// Construct a new material for a pipeline
    this(string pipelineName, TexturedObjSurface objSurface){
        // initialization
        super(pipelineName);

        // Load textures if paths are available
        string diffusePath = objSurface.GetDiffuseMapPath();
        if(diffusePath !is null && diffusePath.length > 0) {
            // Check if file exists first
            if(std.file.exists(diffusePath)) {
                // Get PPM dimensions
                PPM tempPpm;
                tempPpm.LoadPPMImage(diffusePath);
                
                // Use dimensions from the PPM
                mDiffuseMap = new Texture(diffusePath, tempPpm.mWidth, tempPpm.mHeight);
                mHasDiffuseMap = true;
                writeln("Loaded diffuse texture: ", diffusePath, " (", 
                        tempPpm.mWidth, "x", tempPpm.mHeight, ")");
            } else {
                writeln("Diffuse texture file not found: ", diffusePath);
            }
        }

        // Load specular map if available
        string specPath = objSurface.GetSpecMapPath();
        if(specPath !is null && specPath.length > 0) {
            try {
                mSpecularMap = new Texture(specPath, 0, 0);
                mHasSpecularMap = true;
                writeln("Loaded specular texture: ", specPath);
            } catch(Exception e) {
                writeln("Failed to load specular texture: ", e.msg);
            }
        }
        
        // Load normal map if available
        string normalPath = objSurface.GetNormalMapPath();
        if(normalPath !is null && normalPath.length > 0) {
            try {
                mNormalMap = new Texture(normalPath, 0, 0);
                mHasNormalMap = true;
                writeln("Loaded normal texture: ", normalPath);
            } catch(Exception e) {
                writeln("Failed to load normal texture: ", e.msg);
            }
        }
    }

    override void Update(){

        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);
        
        // Clear previous errors
        while(glGetError() != GL_NO_ERROR) {}
        
        // Set diffuse texture if available
        if(mHasDiffuseMap && "diffuseMap" in mUniformMap) {
            // Activate texture unit 0
            glActiveTexture(GL_TEXTURE0);
            
            // Bind texture
            glBindTexture(GL_TEXTURE_2D, mDiffuseMap.mTextureID);
            
            // Set uniform
            mUniformMap["diffuseMap"].Set(0);
            
            // Check for errors
            GLenum err = glGetError();
            if(err != GL_NO_ERROR) {
                writeln("Error binding diffuse texture: ", err);
            }
        }
        
        // Set specular texture if available
        if(mHasSpecularMap && "specularMap" in mUniformMap) {
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, mSpecularMap.mTextureID);
            mUniformMap["specularMap"].Set(1);
            
        }
        
        // Set normal texture if available
        if(mHasNormalMap && "normalMap" in mUniformMap) {
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, mNormalMap.mTextureID);
            mUniformMap["normalMap"].Set(2);
        }
        
        // Set flag uniforms to indicate which textures are available
        if("hasDiffuseMap" in mUniformMap) {
            mUniformMap["hasDiffuseMap"].Set(mHasDiffuseMap ? 1 : 0);
        }
        
        if("hasSpecularMap" in mUniformMap) {
            mUniformMap["hasSpecularMap"].Set(mHasSpecularMap ? 1 : 0);
        }
        
        if("hasNormalMap" in mUniformMap) {
            mUniformMap["hasNormalMap"].Set(mHasNormalMap ? 1 : 0);
 
        }
        if("lightPos" in mUniformMap) {
					mUniformMap["lightPos"].Transfer();
		}
        if("viewPos" in mUniformMap) {
            mUniformMap["viewPos"].Transfer();
        }

    }

    // static method to disable all debugging
    static void DisableGlobalDebug() {
        sGlobalDebugEnabled = false;
    }
    
    // static method to enable all debugging
    static void EnableGlobalDebug() {
        sGlobalDebugEnabled = true;
    }
    
    // Instance method to force debug output again
    void ForceDebugOutput() {
        mDebugPrinted = false;
    }

    void DiagnoseTextures() {
        // Get currently bound texture
        GLint currentTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
        writeln("Currently bound texture: ", currentTexture);
        
        // Check if textures exist and their IDs
        if(mHasDiffuseMap) {
            writeln("Diffuse texture ID: ", mDiffuseMap.mTextureID);
        } else {
            writeln("No diffuse texture");
        }

        // Check if specular map exists
        if(mHasSpecularMap) {
            writeln("Specular texture ID: ", mSpecularMap.mTextureID);
        } else {
            writeln("No specular texture");
        }
        
        // Check if normal map exists
        if(mHasNormalMap) {
            writeln("Normal texture ID: ", mNormalMap.mTextureID);
        } else {
            writeln("No normal texture");
        }
        
        // Check uniform locations
        if("diffuseMap" in mUniformMap) {
            writeln("diffuseMap uniform location: ", mUniformMap["diffuseMap"].mCachedUniformLocation);
        }
        
        if("hasDiffuseMap" in mUniformMap) {
            writeln("hasDiffuseMap uniform location: ", mUniformMap["hasDiffuseMap"].mCachedUniformLocation);
        }
    }
}