/// A specialized MeshNode for instanced rendering
module instancedmeshnode;

import std.stdio;
import mesh;
import materials;
import geometry;
import scene;
import linear;

/// MeshNode for instanced rendering that doesn't use a model matrix
class InstancedMeshNode : MeshNode {
    this(string name, ISurface geometry, IMaterial material) {
        super(name, geometry, material);
    }

    override void Update() {
        // Update the material without setting a model matrix
        mMaterial.Update();

        // Update all uniforms except uModel
        foreach(u ; mMaterial.mUniformMap) {
            u.Transfer();
        }

        // Render the mesh
        mGeometry.Render();
    }
}