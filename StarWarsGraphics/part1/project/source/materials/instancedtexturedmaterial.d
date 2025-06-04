/// Material for instanced textured rendering
module instancedtexturedmaterial;

import material;
import std.stdio;
import bindbc.opengl;
import pipeline;
import texture;
import instancedtexturedobj;

/// Material for instanced textured rendering
class InstancedTexturedMaterial : IMaterial {
    Texture mDiffuseMap;
    Texture mSpecularMap;
    Texture mNormalMap;
    bool mHasDiffuseMap = false;
    bool mHasSpecularMap = false;
    bool mHasNormalMap = false;
    
    /// Constructor for instanced textured material
    this(string pipelineName, InstancedTexturedObjSurface objSurface) {
        super(pipelineName);
        
        // Load textures if paths are available
        string diffusePath = objSurface.GetDiffuseMapPath();
        if(diffusePath !is null && diffusePath.length > 0) {
            try {
                mDiffuseMap = new Texture(diffusePath, 0, 0);
                mHasDiffuseMap = true;
                writeln("Loaded diffuse texture for instanced rendering: ", diffusePath);
            } catch(Exception e) {
                writeln("Failed to load diffuse texture: ", e.msg);
            }
        }
        
        // Load specular map if available
        string specPath = objSurface.GetSpecMapPath();
        if(specPath !is null && specPath.length > 0) {
            try {
                mSpecularMap = new Texture(specPath, 0, 0);
                mHasSpecularMap = true;
                writeln("Loaded specular texture for instanced rendering: ", specPath);
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
                writeln("Loaded normal texture for instanced rendering: ", normalPath);
            } catch(Exception e) {
                writeln("Failed to load normal texture: ", e.msg);
            }
        }
    }
    
    /// Update the material and bind textures
    override void Update() {
        // Set our active Shader graphics pipeline
        PipelineUse(mPipelineName);
        
        // Set diffuse texture if available
        if(mHasDiffuseMap && "diffuseMap" in mUniformMap) {
            // Activate texture unit 0
            glActiveTexture(GL_TEXTURE0);
            
            // Bind texture
            glBindTexture(GL_TEXTURE_2D, mDiffuseMap.mTextureID);
            
            // Set uniform
            mUniformMap["diffuseMap"].Set(0);
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
    }
}