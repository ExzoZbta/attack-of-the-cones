module light;

import linear;
import mesh;
import materials;
import scene;
import std.math;
import geometry;
import geometry.cube;

/// Light in the scene
class Light {
    vec3 mPosition;
    vec3 mColor;
    float mIntensity;
    float mRadius;
    
    // Orbit movement
    float mAngle = 0.0f;
    float mOrbitRadius = 3.0f;
    float mOrbitSpeed = 0.01f;
    float mOrbitHeight = 0.5f;
    
    MeshNode mLightMesh;
    
    this(vec3 position, vec3 color, float intensity, float radius = 50.0f) {
        mPosition = position;
        mColor = color;
        mIntensity = intensity;
        mRadius = radius;
    }
    
    /// Update the light position for orbit animation
    void Update() {
        // Update angle
        mAngle += mOrbitSpeed;
        if (mAngle > 2 * PI) mAngle -= 2 * PI;
        
        // Calculate position
        mPosition.x = mOrbitRadius * cos(mAngle);
        mPosition.z = mOrbitRadius * sin(mAngle);
        mPosition.y = mOrbitHeight;
        
        // Update the visual representation if it exists
        if (mLightMesh !is null) {
            mLightMesh.mModelMatrix = MatrixMakeTranslation(mPosition);
            // Make it smaller than the main object
            mLightMesh.mModelMatrix = mLightMesh.mModelMatrix * MatrixMakeScale(vec3(0.2f, 0.2f, 0.2f));
        }
    }
}