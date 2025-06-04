/// Material for instanced rendering
module instancedmaterial;

import material;
import std.stdio;
import bindbc.opengl;
import pipeline;

/// Material for instanced rendering that doesn't use a model matrix
class InstancedMaterial : IMaterial {
    /// Constructor for instanced material
    this(string pipelineName) {
        super(pipelineName);
    }

    /// Update the material
    override void Update() {
        // Set our active Shader graphics pipeline
        PipelineUse(mPipelineName);
    }
}