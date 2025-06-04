#version 410 core

in vec2 vTexCoords;
in vec4 vWorldCoords;

out vec4 fragColor;

uniform float gHeight0 = 20.0;
uniform float gHeight1 = 50.0;
uniform float gHeight2 = 130.0;
uniform float gHeight3 = 200.0;

vec3 GetColor(){
		vec3 color = vec3(1.0,1.0,1.0);

		// Blended transitions
		// TODO The below is not quite right
		// You'll want to sample different textures based
		// on the 'heights' of the terrain.
		// Then you'll want to also 'mix' them so you get a smooth
		// transition from one to the other for all or a portion of the texture.
		// color+=texture(sampler1,vTexCoords * vWorldCoords[0]).rgb*0.25;
		// color+=texture(sampler2,vTexCoords * vWorldCoords[1]).rgb*0.25;
		// color+=texture(sampler3,vTexCoords * vWorldCoords[2]).rgb*0.25;
		// color+=texture(sampler4,vTexCoords * vWolrdCoords[3]).rgb*0.25;

		//vec3 color1 = vec3(0.36, 0.25, 0.20);
		vec3 color1 = vec3(0.64, 0.32, 0.18);
		vec3 color2 = vec3(0.72, 0.25, 0.05);
		vec3 color3 = vec3(0.58, 0.27, 0.21);
		vec3 color4 = vec3(0.63, 0.32, 0.18);

		float Height = vWorldCoords.y;
		if(Height < gHeight0){
			color = color1;
		}
		else if (Height < gHeight1){
			float Delta = gHeight1 - gHeight0;
			float Factor = (Height - gHeight0) / Delta;
			color = mix(color1, color2, Factor);
		}
		else if (Height < gHeight2){
			float Delta = gHeight2 - gHeight1;
			float Factor = (Height - gHeight1) / Delta;
			color = mix(color2, color3, Factor);
		}
		else if (Height < gHeight3){
			float Delta = gHeight3 - gHeight2;
			float Factor = (Height - gHeight2) / Delta;
			color = mix(color3, color4, Factor);
		}
		else{
			color = color4;
		}
		
		
		return color;
}

void main(){

		fragColor = vec4(GetColor(), 1.0);
}