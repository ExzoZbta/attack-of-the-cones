/// This file represents a specialized mesh abstraction for instanced rendering.
module instancedmesh;

import std.stdio;

import linear;
import materials;
import scene;
import geometry;
import mesh;

import bindbc.opengl;

/// A specialized MeshNode for instanced rendering that doesn't require uModel uniform
class InstancedMeshNode : MeshNode {
    
    this(string name, ISurface geometry, IMaterial material) {
        super(name, geometry, material);
    }
    
    override void Update() {
        /// Update the material
        mMaterial.Update();
        
        // For instanced rendering, we don't need to update model matrix via uniforms
        // as it's handled per-instance in the vertex shader
        
        // Update all of the uniform values
        // This will happen prior to the draw call
        foreach(u ; mMaterial.mUniformMap) {
            u.Transfer();
        }
        
        /// Render the Mesh
        // Draw our arrays
        mGeometry.Render();
    }
}