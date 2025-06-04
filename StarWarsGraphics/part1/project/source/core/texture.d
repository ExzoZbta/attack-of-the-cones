/// Module to handle texture loading
module texture;

import image;

import bindbc.opengl;
import std.stdio;
import std.file;
import std.algorithm;

/// Abstraction for generating an OpenGL texture on GPU memory from an image filename.
class Texture{
		GLuint mTextureID;
		// Create a new texture
		this(string filename, int width, int height) {
			writeln("Creating texture from ", filename);
			
			if(!std.file.exists(filename)) {
				writeln("ERROR: Texture file not found: ", filename);
				return;
			}
			
			// Generate a new texture ID
			glGenTextures(1, &mTextureID);
			writeln("Generated texture ID: ", mTextureID);
			
			// Bind the texture
			glBindTexture(GL_TEXTURE_2D, mTextureID);
			
			// Load the image data
			PPM ppm;
			ubyte[] image_data = ppm.LoadPPMImage(filename);
			
			if(image_data.length == 0) {
				writeln("ERROR: Failed to load image data from ", filename);
				return;
			}
			
			// Use dimensions from the PPM
			width = ppm.mWidth;
			height = ppm.mHeight;
			
			writeln("Texture dimensions: ", width, "x", height);
			
			// Set texture parameters before uploading data
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			
			// Ensure pixel storage alignment is correct
			glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
			
			// Upload texture data
			glTexImage2D(
				GL_TEXTURE_2D,
				0,
				GL_RGB,
				width,
				height,
				0,
				GL_RGB,
				GL_UNSIGNED_BYTE,
				image_data.ptr
			);
			
			// Check for errors
			GLenum err = glGetError();
			if(err != GL_NO_ERROR) {
				writeln("OpenGL Error after texture upload: ", err);
				
				// Try a different approach with a temporary array
				ubyte[] tempData = new ubyte[width * height * 3];
				for(int i = 0; i < image_data.length && i < tempData.length; i++) {
					tempData[i] = image_data[i];
				}
				
				// Temporary array
				glTexImage2D(
					GL_TEXTURE_2D,
					0,
					GL_RGB,
					width,
					height,
					0,
					GL_RGB,
					GL_UNSIGNED_BYTE,
					tempData.ptr
				);
				
				err = glGetError();
				if(err != GL_NO_ERROR) {
					writeln("Still error after second attempt: ", err);
				} else {
					writeln("Second texture upload attempt succeeded");
				}
			}
			
			// Generate mipmaps
			glGenerateMipmap(GL_TEXTURE_2D);
			
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
			
			writeln("Texture creation complete: ", filename);
		}
}	