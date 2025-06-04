/// Material for rendering 3D dustcloud
module dustcloudmaterial;

import pipeline, materials, uniform, linear;
import bindbc.opengl;
import std.stdio;

/// Represents a material for rendering volumetric dustclouds
class DustCloudMaterial : IMaterial {
    float mTime = 0.0f;
    vec3 mLightPos;
    vec3 mCameraPos;

    /// Constructor that sets up the material with the dustcloud pipeline
    this(string pipelineName = "instanceddustcloud") {
        // Initialize with base material using our pipeline
        super(pipelineName);

        // Default light position
        mLightPos = vec3(0.0f, 5.0f, 0.0f);
        mCameraPos = vec3(0.0f, 0.0f, 5.0f);

        // Add time uniform
        AddUniform(new Uniform("uTime", 0.0f));
        
        // Add light position uniform
        AddUniform(new Uniform("uLightPosition", "vec3", &mLightPos));

        // Add camera position uniform
        AddUniform(new Uniform("uCameraPosition", "vec3", &mCameraPos));

    }

    /// Update function is called each frame to update time and other uniforms
    override void Update() {
        // Call the base update to use the pipeline
        super.Update();
        
        // Update time uniform
        Uniform* timeUniform = "uTime" in mUniformMap;
        if (timeUniform !is null) {
            timeUniform.Set(mTime);
            // writeln("  - Setting time: ", mTime);
        } else {
            writeln("  - ERROR: Couldn't find uTime uniform");
        }
        
        // Make sure camera and light positions are updated
        Uniform* camPosUniform = "uCameraPosition" in mUniformMap;
        if (camPosUniform !is null) {
            camPosUniform.Set(mCameraPos.DataPtr());
            // writeln("  - Setting camera pos: ", mCameraPos.x, ", ", mCameraPos.y, ", ", mCameraPos.z);
        } else {
            writeln("  - ERROR: Couldn't find uCameraPosition uniform");
        }
        
        Uniform* lightPosUniform = "uLightPosition" in mUniformMap;
        if (lightPosUniform !is null) {
            lightPosUniform.Set(mLightPos.DataPtr());
            // writeln("  - Setting light pos: ", mLightPos.x, ", ", mLightPos.y, ", ", mLightPos.z);
        } else {
            writeln("  - ERROR: Couldn't find uLightPosition uniform");
        }
    }
    
    /// Update the camera position uniform
    void UpdateCameraPosition(vec3 cameraPos) {
        mCameraPos = cameraPos;
    }
    
    /// Update the light position uniform
    void UpdateLightPosition(vec3 lightPos) {
        mLightPos = lightPos;
    }
}