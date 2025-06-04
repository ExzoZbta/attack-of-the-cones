# 'Attack of the Cones' - Real-Time 3D Graphics Project
## by Richard Corrente and Archit Kumar
 
## Project Description
This project is an advanced 3D graphics application built using OpenGL 4.1 and the D programming language, demonstrating various real-time graphics techniques and concepts. The project features a dynamic Star Wars-themed scene with multiple advanced rendering features.

### Key Technical Features
1. Instanced Rendering
    - Support for rendering multiple instances of the same geometry
    - Efficient handling of large numbers of objects (ex: 1000 clone troopers)
    - Per-instance transformations and animations
    - Optimized vertex buffer management
2. Advanced Scene Management
    - Implemented a hierarchical scene graph system for efficient object management
    - Dynamic scene traversal with depth-first search for optimal rendering
    - Support for complex object hierarchies and transformations
3. Real-time Lighting System
    - Dynamic point light implementation with customizable properties
    - Instanced light cubes with particle-like behavior
    - Light position tracking and closest-point calculations
4. Particle System and Environmental Effects
    - Multi-layered dust cloud system with different densities and behaviors
    - Player-centered dust effects
    - Ground-level dust particles
5. Material System
    - Support for multiple material types (basic, textured, instanced)
    - Dynamic uniform management
    - Support for diffuse, specular, and normal mapping

### Technical Implementation Details
- Built using OpenGL 4.1
- Implemented in Dlang
- Used SDL for window management and input handling
- Frame rate capped at 60 FPS for consistent performance


## YouTube/Dropbox/Drive Link: 

**https://youtu.be/tqLeiEE3g3s**

## RUNNING INSTRUCTIONS: 
To run the program, navigate to StarWarsGraphics/part1/project.
- Type "dub" with no arguments to place 1000 clones in the scene.
- Use the first command line argument to specify the number of clones you want to spawn
- Use the second command line argument to remove the clones' helmets.

Note: this program runs well on Mac -- Linux/Windows may experience a few issues with the particle system. 

## Screenshots

![screenshot1](https://i.imgur.com/wtLVVwL.png)
![screenshot2](https://i.imgur.com/vM03jLO.png)
![screenshot3](https://i.imgur.com/jYkEBSD.png)
![screenshot4](https://i.imgur.com/9G9xltU.png)