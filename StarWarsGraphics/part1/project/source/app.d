module app;

import graphics_app;
import std.stdio;
import std.getopt;
import std.conv;

/// Program entry point 
/// NOTE: When debugging, this is '_Dmain'
void main(string[] args)
{
    string mike_mode = null;
    int num_clones = 1000;
    
    // command-line argument handling
    if (args.length > 1) {
        num_clones = to!int(args[1]);
    }

    if (args.length > 2){
        mike_mode = args[2];
    }
    
    // Create our graphics application
    GraphicsApp app = GraphicsApp(4, 1, num_clones, mike_mode);

    app.Loop();
    
}
