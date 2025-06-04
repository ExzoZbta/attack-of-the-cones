/// Module to handle texture loading
module image;

import std.file, std.conv, std.algorithm, std.range, std.stdio, std.file, std.string, std.math;

/// Simple struct for loading image/pixel data in PPM format.
struct PPM{

		int mWidth 	= 256;
		int mHeight = 256;
		int mRange  = 255;
		ubyte[] mPixels;

		// PPM image loader
		ubyte[] LoadPPMImage(string filename) {
			writeln("Loading PPM image: ", filename);
			
			if(!std.file.exists(filename)) {
				writeln("ERROR: File does not exist: ", filename);
				return [];
			}
			
			try {
				// Read the file as bytes
				auto fileData = cast(string)read(filename);
				
				auto lines = splitLines(fileData);
				
				// Process header
				string format;
				int width = 0, height = 0, maxVal = 0;
				int lineIndex = 0;
				
				// Skip comments and get format (P3)
				while(lineIndex < lines.length) {
					auto line = lines[lineIndex++].strip();
					if(line.length == 0 || line[0] == '#') continue;
					
					format = line;
					break;
				}
				
				if(format != "P3") {
					writeln("ERROR: Only P3 PPM format is supported, found: ", format);
					return [];
				}
				
				// Get dimensions
				while(lineIndex < lines.length) {
					auto line = lines[lineIndex++].strip();
					if(line.length == 0 || line[0] == '#') continue;
					
					auto parts = line.split();
					if(parts.length >= 2) {
						width = to!int(parts[0]);
						height = to!int(parts[1]);
						break;
					}
				}
				
				// Get max value
				while(lineIndex < lines.length) {
					auto line = lines[lineIndex++].strip();
					if(line.length == 0 || line[0] == '#') continue;
					
					maxVal = to!int(line);
					break;
				}
				
				mWidth = width;
				mHeight = height;
				mRange = maxVal;
				
				writeln("PPM header parsed: ", width, "x", height, ", max value: ", maxVal);
				
				// Gather all remaining lines into one block of tokens
				string allData;
				for(int i = lineIndex; i < lines.length; i++) {
					auto line = lines[i];
					if(line.length > 0 && line[0] != '#') {
						allData ~= " " ~ line;
					}
				}

				// Allocate pixel buffer
				ubyte[] pixels = new ubyte[width * height * 3];
				
				// Split into value tokens
				auto tokens = allData.strip().split();
				writeln("Found ", tokens.length, " pixel values in file");
				
				// The total number of tokens should be width * height * 3
				if(tokens.length < width * height * 3) {
					writeln("WARNING: Not enough pixel data in file");
				}
				
				// Read the data in a standard row-major format
				int tokenIndex = 0;
				for(int y = 0; y < height; y++) {
					for(int x = 0; x < width; x++) {
						// Calculate destination index
						// Flip the y-coordinate to load from top-left to bottom-right
						int flippedY = height - 1 - y;
						int pixelIndex = (flippedY * width + x) * 3;
						
						// Read RGB values
						for(int c = 0; c < 3; c++) {
							if(tokenIndex < tokens.length) {
								int value = to!int(tokens[tokenIndex++]);
								
								// Scale if needed
								if(maxVal != 255) {
									value = cast(int)((value * 255.0) / maxVal);
								}
								
								pixels[pixelIndex + c] = cast(ubyte)value;
							}
						}
					}
				}
				
				// Debug: Print some pixel values
				writeln("Sample pixels (RGB) after processing:");
				for(int y = 0; y < min(2, height); y++) {
					for(int x = 0; x < min(2, width); x++) {
						int base = (y * width + x) * 3;
						writefln("  Pixel(%d,%d): (%d, %d, %d)", x, y, 
								pixels[base], pixels[base+1], pixels[base+2]);
					}
				}
				
				return pixels;
			}
			catch(Exception e) {
				writeln("Error loading PPM: ", e.msg);
				return [];
			}
		}
}
