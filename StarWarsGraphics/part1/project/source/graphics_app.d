/// The main graphics application with the main graphics loop.
module graphics_app;
import std.stdio;
import std.math;
import core;
import mesh, linear, scene, materials, geometry;
import platform;
import light;
import geometry.cube;
import std.conv;
import std.random;
import uniform;

import bindbc.sdl;
import bindbc.opengl;

/// The main graphics application.
struct GraphicsApp{
		bool mGameIsRunning=true;
		bool mRenderWireframe = false;
		SDL_GLContext mContext;
		SDL_Window* mWindow;

		// Scene
		SceneTree mSceneTree;
		// Camera
		Camera mCamera;
		// Renderer
		Renderer mRenderer;
		// Light
		Light mLight;
		vec3 mLightPosition;
		float mTime = 0.0f;
		float* mTimePtr;
		vec3* mLightPosPtr;

		// Fired light cube properties
		MeshNode mFiredLightNode;
		vec3 mFiredLightPosition;
		vec3 mFiredLightDirection;
		float mFiredLightSpeed = 0.5f;
		float mFiredLightMaxDistance = 10.0f;
		float mFiredLightCurrentDistance = 0.0f;
		bool mIsFiredLightActive = false;
		bool use_mike_mode = false;

		private InstancedLightCubes mInstancedLights;
		private vec3 mClosestLightPosition = vec3(0.0f, 1.0f, 0.0f);

		private int CloneTrooperCount = 1000;

		// DustCloud properties
		MeshNode[] mDustCloudNodes;
		int mDustCloudCount = 10;  // Number of dust clouds
		float mDustCloudRadius = 15.0f;  // Radius of each cloud
        DustCloudMaterial mDustCloudMaterial;  // Shared material

		// OBJ file path
		string mObjFilePath = "./assets/sphere.obj";
		// MTL file path
		string mMtlFilePath = "./assets/clonetrooper/clone.mtl";

		/// Setup OpenGL and any libraries
		this(int major_ogl_version, int minor_ogl_version, int num_clones, string mike_mode){

				if(mike_mode != null){
					mMtlFilePath = "./assets/clonetrooper/mike_obj.mtl";
					use_mike_mode = true;
				}

				CloneTrooperCount = num_clones;

				// Setup SDL OpenGL Version
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version );
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version );
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
				// We want to request a double buffer for smooth updating.
				SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
				SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

				// Create an application window using OpenGL that supports SDL
				mWindow = SDL_CreateWindow( "dlang - OpenGL 4+ Graphics Framework",
								SDL_WINDOWPOS_UNDEFINED,
								SDL_WINDOWPOS_UNDEFINED,
								640,
								480,
								SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN );

				// Create the OpenGL context and associate it with our window
				mContext = SDL_GL_CreateContext(mWindow);

				// Load OpenGL Function calls
				auto retVal = LoadOpenGLLib();

				// Check OpenGL version
				GetOpenGLVersionInfo();

				// Create a renderer
				mRenderer = new Renderer(mWindow,640,480);

				// Create a camera
				mCamera = new Camera();
				mCamera.SetCameraPosition(0.0f, 0.0f, 2.5f);


				// Create (or load) a Scene Tree
				mSceneTree = new SceneTree("root");
		}

		/// Destructor
		~this(){
			// Destroy our context
			SDL_GL_DeleteContext(mContext);
			// Destroy our window
			SDL_DestroyWindow(mWindow);
		}

		/// Handle input
		void Input(){
				// Store an SDL Event
				SDL_Event event;
				while(SDL_PollEvent(&event)){
						if(event.type == SDL_QUIT){
								writeln("Exit event triggered (probably clicked 'x' at top of the window)");
								mGameIsRunning= false;
						}
						if(event.type == SDL_KEYDOWN){
								if(event.key.keysym.scancode == SDL_SCANCODE_ESCAPE){
										writeln("Pressed escape key and now exiting...");
										mGameIsRunning= false;
								}else if(event.key.keysym.sym == SDLK_TAB){
										mRenderWireframe = !mRenderWireframe;
								}
								else if(event.key.keysym.sym == SDLK_s){
										mCamera.MoveBackward();
								}
								else if(event.key.keysym.sym == SDLK_w){
										mCamera.MoveForward();
								}
								else if(event.key.keysym.sym == SDLK_a){
										mCamera.MoveLeft();
								}
								else if(event.key.keysym.sym == SDLK_d){
										mCamera.MoveRight();
								}
								else if(event.key.keysym.sym == SDLK_UP){
										mCamera.MoveUp();
								}
								else if(event.key.keysym.sym == SDLK_DOWN){
										mCamera.MoveDown();
								}
								writeln("Camera Position: ",mCamera.mEyePosition);
						}
				}

                // Retrieve the mouse position
                int mouseX,mouseY;
                SDL_GetMouseState(&mouseX,&mouseY);
                mCamera.MouseLook(mouseX,mouseY);
		}

		/// A helper function to setup a scene.
		/// NOTE: In the future this can use a configuration file to otherwise make our graphics applications
		///       data-driven.
		void SetupScene(){

				// Create a pipeline for basic materials
    			Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
				
				// Create a pipeline for textured objects
    			Pipeline texturedPipeline = new Pipeline("textured","./pipelines/textured/textured.vert","./pipelines/textured/textured.frag");

				Pipeline litTexturedPipeline = new Pipeline("lit_textured","./pipelines/textured/lit_textured.vert","./pipelines/textured/lit_textured.frag");

				// Create a pipeline for the light cube
				Pipeline lightPipeline = new Pipeline("light","./pipelines/light/light.vert","./pipelines/light/light.frag");
				IMaterial lightMaterial = new BasicMaterial("light");

				// Create a pipeline for dustcloud 
				Pipeline dustcloudPipeline = new Pipeline("instanceddustcloud","./pipelines/instanceddustcloud/instanceddustcloud.vert","./pipelines/instanceddustcloud/instanceddustcloud.frag");

				// Create a pipeline for instanced rendering
				Pipeline instancedPipeline = new Pipeline("instanced", "./pipelines/instanced/instanced.vert", "./pipelines/instanced/instanced.frag");

				// Create a pipeline for instanced lights
				Pipeline instancedLightPipeline = new Pipeline("instancedlight",
					"./pipelines/instancedlight/instancedlight.vert",
					"./pipelines/instancedlight/instancedlight.frag");
					
				// Create terrain
				Pipeline texturePipeline = new Pipeline("multiTexturePipeline","./pipelines/multitexture/basic.vert","./pipelines/multitexture/basic.frag");
				IMaterial multiTextureMaterial = new MultiTextureMaterial("multiTexturePipeline","./assets/sand.ppm","./assets/grass.ppm","./assets/dirt.ppm","./assets/snow.ppm");
				// multiTextureMaterial.AddUniform(new Uniform("sampler1", 0));
				// multiTextureMaterial.AddUniform(new Uniform("sampler2", 1));
				// multiTextureMaterial.AddUniform(new Uniform("sampler3", 2));
				// multiTextureMaterial.AddUniform(new Uniform("sampler4", 3));
				multiTextureMaterial.AddUniform(new Uniform("uModel", "mat4", null));
				multiTextureMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
				multiTextureMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

				ISurface terrain = new SurfaceTerrain(256,256,"./assets/custom2.ppm"); 
				MeshNode  m2        			= new MeshNode("terrain",terrain,multiTextureMaterial);

				// Position terrain 
				m2.mModelMatrix = MatrixMakeTranslation(vec3(-35.0f, -1.5f, -60.0f));
				mSceneTree.GetRootNode().AddChildSceneNode(m2);

				// Create an object and add it to our scene tree
				writeln("Loading OBJ file: ", mObjFilePath);
				ISurface obj;
				ISurface mikeobj; 
				try {
					if (mMtlFilePath !is null && mMtlFilePath.length > 0) {
						// Create a textured OBJ
						obj = new TexturedObjSurface(mObjFilePath, mMtlFilePath);
						
						// Create a textured material
						IMaterial texturedMaterial = new TexturedObjMaterial("textured", cast(TexturedObjSurface)obj);
						
						// Add needed uniforms
						texturedMaterial.AddUniform(new Uniform("uModel", "mat4", null));
						texturedMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
						texturedMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
						
						// Texture samplers
						texturedMaterial.AddUniform(new Uniform("diffuseMap", 0));
						texturedMaterial.AddUniform(new Uniform("specularMap", 1));
						texturedMaterial.AddUniform(new Uniform("normalMap", 2));
						// Texture lighting
						texturedMaterial.AddUniform(new Uniform("lightPos", "vec3", &mFiredLightPosition));
						texturedMaterial.AddUniform(new Uniform("viewPos", "vec3", mCamera.mEyePosition.DataPtr()));
						
						// Texture availability flags
						texturedMaterial.AddUniform(new Uniform("hasDiffuseMap", 0));
						texturedMaterial.AddUniform(new Uniform("hasSpecularMap", 0));
						texturedMaterial.AddUniform(new Uniform("hasNormalMap", 0));

						// Create instanced cones (
						ISurface instancedCones = new InstancedTexturedObjSurface("./assets/clonetrooper/justcone.obj", "./assets/clonetrooper/waffle.mtl", CloneTrooperCount);
						IMaterial instancedMaterial = new InstancedTexturedMaterial("instanced", cast(InstancedTexturedObjSurface)instancedCones);

						// Add uniforms for instanced rendering
						instancedMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
						instancedMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
						instancedMaterial.AddUniform(new Uniform("lightPos", "vec3", &mFiredLightPosition));
						instancedMaterial.AddUniform(new Uniform("viewPos", "vec3", mCamera.mEyePosition.DataPtr()));

						// Add texture uniforms
						instancedMaterial.AddUniform(new Uniform("diffuseMap", 0));
						instancedMaterial.AddUniform(new Uniform("specularMap", 1));
						instancedMaterial.AddUniform(new Uniform("normalMap", 2));
						instancedMaterial.AddUniform(new Uniform("hasDiffuseMap", 1));
						instancedMaterial.AddUniform(new Uniform("hasSpecularMap", 1));
						instancedMaterial.AddUniform(new Uniform("hasNormalMap", 1));

						// Create mesh node for instanced cones
						InstancedMeshNode instancedConesNode = new InstancedMeshNode("instancedCones", instancedCones, instancedMaterial);
						mSceneTree.GetRootNode().AddChildSceneNode(instancedConesNode);

						// Create instanced spheres on top of cones
						ISurface instancedSpheres = new InstancedSphereOnObjSurface(
							"./assets/sphere.obj",
							mMtlFilePath, 
							cast(InstancedTexturedObjSurface)instancedCones);

						// Create material for textured spheres
						IMaterial sphereMaterial = new InstancedSphereMaterial("instanced", cast(InstancedSphereOnObjSurface)instancedSpheres);

						// Add uniforms for instanced rendering
						sphereMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
						sphereMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
						sphereMaterial.AddUniform(new Uniform("lightPos", "vec3", &mFiredLightPosition));
						sphereMaterial.AddUniform(new Uniform("viewPos", "vec3", mCamera.mEyePosition.DataPtr()));

						// Add texture uniforms
						sphereMaterial.AddUniform(new Uniform("diffuseMap", 0));
						sphereMaterial.AddUniform(new Uniform("specularMap", 1));
						sphereMaterial.AddUniform(new Uniform("normalMap", 2));
						sphereMaterial.AddUniform(new Uniform("hasDiffuseMap", 1));
						sphereMaterial.AddUniform(new Uniform("hasSpecularMap", 1));
						sphereMaterial.AddUniform(new Uniform("hasNormalMap", 1));

						// Create mesh node for instanced spheres
						InstancedMeshNode instancedSpheresNode = new InstancedMeshNode("instancedSpheres", instancedSpheres, sphereMaterial);
						mSceneTree.GetRootNode().AddChildSceneNode(instancedSpheresNode);

						// Create instanced lights that fire from all spheres
						mInstancedLights = new InstancedLightCubes(cast(InstancedSphereOnObjSurface)instancedSpheres);

						// Create material for instanced lights
						IMaterial lightsInstancedMaterial = new InstancedMaterial("instancedlight");

						// Add uniforms for instanced rendering
						lightsInstancedMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
						lightsInstancedMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));


						// Create mesh node for instanced lights
						InstancedMeshNode instancedLightsNode = new InstancedMeshNode("instancedLights", mInstancedLights, lightsInstancedMaterial);
						mSceneTree.GetRootNode().AddChildSceneNode(instancedLightsNode);

						//Adding Skybox
						// Create a textured OBJ
						ISurface skyObj = new TexturedObjSurface(mObjFilePath, "./assets/skybox/sky.mtl");
						
						// Create a textured material using the textured pipeline
						IMaterial skyMaterial = new TexturedObjMaterial("lit_textured", cast(TexturedObjSurface)skyObj);
						
						// Add needed uniforms for textured pipeline
						skyMaterial.AddUniform(new Uniform("uModel", "mat4", null));
						skyMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
						skyMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
						skyMaterial.AddUniform(new Uniform("diffuseMap", 0));
						skyMaterial.AddUniform(new Uniform("hasDiffuseMap", 1));

						// Create mesh node with textured material
						MeshNode sky = new MeshNode("sky", skyObj, skyMaterial);
						// Scale the sphere
						sky.mModelMatrix = MatrixMakeScale(vec3(100.0f, 100.0f, 100.0f));
						mSceneTree.GetRootNode().AddChildSceneNode(sky);

						// Disable debug output after initial setup
        			    TexturedObjMaterial.DisableGlobalDebug();
					} else {
						// Use the standard OBJ loader if no MTL file provided
						obj = new SurfaceOBJ(mObjFilePath);

						// Create a pipeline and associate it with a material that can be attached to meshes.
						IMaterial basicMaterial = new BasicMaterial("basic");
						
						// Add three uniforms to the basic material.
						basicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
						basicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
						basicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
						
						// Add light position to basic material
						writeln("Adding lightPos to basic material");
						basicMaterial.AddUniform(new Uniform("lightPos", "vec3", &mFiredLightPosition));

						MeshNode m = new MeshNode("object", obj, basicMaterial);
						mSceneTree.GetRootNode().AddChildSceneNode(m);
					}
					writeln("Successfully loaded OBJ file");
				} catch (Exception e) {
					writeln("Error loading OBJ file: ", e.msg);
					writeln("Using default bunny model");
					obj = new SurfaceOBJ("./assets/sphere.obj");

					// Create basic material
					IMaterial basicMaterial = new BasicMaterial("basic");
					
					// Add three uniforms to the basic material.
					// The 4th parameter is set to the pointer where the value will be updated each frame.
					// Becauses the model matrix will be different among models, then we will just leave
					// this null for now.
					basicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
					basicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
					basicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
					
					basicMaterial.AddUniform(new Uniform("lightPos", "vec3", &mFiredLightPosition));

					MeshNode m = new MeshNode("object", obj, basicMaterial);
					mSceneTree.GetRootNode().AddChildSceneNode(m);
				}

				SetupDustClouds();
		}

		/// Setup the dustcloud system
        void SetupDustClouds() {
			writeln("Setting up dust clouds...");
            // Create shared material
            mDustCloudMaterial = new DustCloudMaterial("instanceddustcloud");
            mDustCloudMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
            mDustCloudMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
            
			mDustCloudMaterial.UpdateCameraPosition(mCamera.mEyePosition);
            mDustCloudMaterial.UpdateLightPosition(mFiredLightPosition);

			// LAYER 0: PLAYER DUST - Central player dust with 30 instances
			ISurface playerDustGeometry = new InstancedDustCloudGeometry(10000, 20.0f, 30);
			MeshNode playerDustNode = new InstancedMeshNode("player_dust", playerDustGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(playerDustNode);
			mDustCloudNodes ~= playerDustNode;
			writeln("Created instanced player-centered dust");

			// LAYER 1: DISTANT SANDSTORM - Obscures the horizon with 20 large instances
			ISurface distantStormGeometry = new InstancedDustCloudGeometry(20000, 100.0f, 20, true);
			MeshNode distantStormNode = new InstancedMeshNode("distant_storm", distantStormGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(distantStormNode);
			mDustCloudNodes ~= distantStormNode;
			writeln("Created instanced distant sandstorm layer");

			// LAYER 2: MID-RANGE DUST - Create horizontal dust sheets with 15 instances
			ISurface midRangeDustGeometry = new InstancedDustCloudGeometry(8000, 60.0f, 15, true);
			MeshNode midRangeDustNode = new InstancedMeshNode("mid_range_dust", midRangeDustGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(midRangeDustNode);
			mDustCloudNodes ~= midRangeDustNode;
			writeln("Created instanced mid-range dust sheets");
			
			// LAYER 3: CHUNKY CLOUDS - Visible dust formations with 25 varied instances
			ISurface chunkyCloudGeometry = new InstancedDustCloudGeometry(15000, 15.0f, 25);
			MeshNode chunkyCloudNode = new InstancedMeshNode("chunky_cloud", chunkyCloudGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(chunkyCloudNode);
			mDustCloudNodes ~= chunkyCloudNode;
			writeln("Created instanced chunky cloud formations");
			
			// LAYER 4: GROUND DUST - Dense near ground with 10 large instances
			ISurface groundDustGeometry = new InstancedDustCloudGeometry(15000, 30.0f, 10, true);
			MeshNode groundDustNode = new InstancedMeshNode("ground_dust", groundDustGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(groundDustNode);
			mDustCloudNodes ~= groundDustNode;
			writeln("Created instanced ground dust layer");
			
			// LAYER 5: PLAYER VICINITY DUST - Close to player with 8 small instances
			ISurface nearDustGeometry = new InstancedDustCloudGeometry(5000, 8.0f, 8);
			MeshNode nearDustNode = new InstancedMeshNode("near_dust", nearDustGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(nearDustNode);
			mDustCloudNodes ~= nearDustNode;
			writeln("Created instanced near-player dust");
			
			// LAYER 6: EXTREME DENSITY - Wall of sand with 15 varied instances
			ISurface extremeDensityGeometry = new InstancedDustCloudGeometry(20000, 40.0f, 15, true);
			MeshNode extremeDensityNode = new InstancedMeshNode("extreme_density", extremeDensityGeometry, mDustCloudMaterial);
			mSceneTree.GetRootNode().AddChildSceneNode(extremeDensityNode);
			mDustCloudNodes ~= extremeDensityNode;
			writeln("Created instanced extreme density sandstorm layer");
			
        }

		/// Update gamestate
		void Update(){
				static float yRotation = 0.0f; 

				mTime += 0.01f;

				// Update instanced lights
				if (mInstancedLights !is null) {
					mInstancedLights.Update();

					vec3 pointOfInterest = mCamera.mEyePosition; // Using camera position
					mClosestLightPosition = mInstancedLights.GetClosestLightPosition(pointOfInterest);
					mFiredLightPosition = mClosestLightPosition; // Update the light position used by shaders
				}

				// Update skybox position to match camera
				MeshNode skyboxNode = cast(MeshNode)mSceneTree.FindNode("sky");
				if (skyboxNode !is null) {
					// Set skybox position to camera position
					skyboxNode.mModelMatrix = MatrixMakeTranslation(mCamera.mEyePosition);
					// Apply the scaling after translation
					skyboxNode.mModelMatrix = skyboxNode.mModelMatrix * MatrixMakeScale(vec3(200.0f, 200.0f, 200.0f));
				}
				
				// Update dust clouds
				if (mDustCloudMaterial !is null) {
					// Update the time uniform in the material
					mDustCloudMaterial.mTime += 0.016f;
										
					// Update light position for the dust clouds
					mDustCloudMaterial.UpdateLightPosition(mFiredLightPosition);
					
					// Optionally animate the dust clouds by moving them
					foreach (size_t i, MeshNode cloud; mDustCloudNodes) {
						// Small continuous movement for the clouds
						float timeOffset = mTime + i * 0.5f;
						
						// Get current position
						mat4 modelMatrix = cloud.mModelMatrix;
						vec3 pos;
						pos.x = modelMatrix.DataPtr()[12]; // Get x translation
						pos.y = modelMatrix.DataPtr()[13]; // Get y translation
						pos.z = modelMatrix.DataPtr()[14]; // Get z translation
						
						// Apply gentle swaying motion
						pos.x += sin(timeOffset * 0.1f) * 0.01f;
						pos.y += cos(timeOffset * 0.07f) * 0.005f;
						pos.z += sin(timeOffset * 0.05f) * 0.01f;
						
						// Apply the new position
						cloud.mModelMatrix = MatrixMakeTranslation(pos);
					}
				}

				// Position object at the scene origin
				MeshNode m = cast(MeshNode)mSceneTree.FindNode("object");
				if (m is null) {
					// Try with "bunny" name for backward compatibility
					m = cast(MeshNode)mSceneTree.FindNode("bunny");
				}
				
				if (m !is null) {
					// Update rotation angle
					yRotation = 90.0f * (PI / 180.0f);
					
					m.mModelMatrix = MatrixMakeTranslation(vec3(0.0f, 0.0f, 0.0f));
					m.mModelMatrix = m.mModelMatrix * MatrixMakeYRotation(yRotation);
					
				}			
		}

		/// Render our scene by traversing the scene tree from a specific viewpoint
		void Render(){
				if(mRenderWireframe){
						glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
				}else{
						glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
				}

				mRenderer.Render(mSceneTree,mCamera);
		}

		/// Process 1 frame
		void AdvanceFrame(){
				Input();
				Update();
				Render();
				
				SDL_Delay(16);	// NOTE: This is a simple way to cap framerate at 60 FPS,
								// 		  you might be inclined to improve things a bit.
		}

		/// Main application loop
		void Loop(){
				// Setup the graphics scene
				SetupScene();

				// Lock mouse to center of screen
				// This will help us get a continuous rotation.
				// NOTE: On occasion folks on virtual machine or WSL may not have this work,
				//       so you'll have to compute the 'diff' and reposition the mouse yourself.
				SDL_WarpMouseInWindow(mWindow,640/2,320/2);

				// Run the graphics application loop
				while(mGameIsRunning){
						AdvanceFrame();
				}
		}
}

