#version 410 core

in vec2 vTexCoords;
in vec4 vWorldCoords;

out vec4 fragColor;

uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D sampler3;
uniform sampler2D sampler4;

uniform float gHeight0 = 64.0;
uniform float gHeight1 = 128.0;
uniform float gHeight2 = 193.0;
uniform float gHeight3 = 256.0;


vec3 GetColor(){
		vec3 color;

		float Height = vWorldCoords.y;
		if (Height < gHeight0) {
			color = texture(sampler1, vTexCoords).rgb;
		} else if (Height < gHeight1) {
			vec3 Color0 = texture(sampler1, vTexCoords).rgb;
			vec3 Color1 = texture(sampler2, vTexCoords).rgb;
			float Delta = gHeight1 - gHeight0;
			float Factor = (Height - gHeight0) / Delta;
			color = mix(Color0, Color1, Factor);
		} else if (Height < gHeight2) {
			vec3 Color0 = texture(sampler2, vTexCoords).rgb;
			vec3 Color1 = texture(sampler3, vTexCoords).rgb;
			float Delta = gHeight2 - gHeight1;
			float Factor = (Height - gHeight1) / Delta;
			color = mix(Color0, Color1, Factor);
		} else if (Height < gHeight3) {
			vec3 Color0 = texture(sampler3, vTexCoords).rgb;
			vec3 Color1 = texture(sampler4, vTexCoords).rgb;
			float Delta = gHeight3 - gHeight2;
			float Factor = (Height - gHeight2) / Delta;
			color = mix(Color0, Color1, Factor);
		} else {
			color = texture(sampler4, vTexCoords).rgb;
		}

		
		return color;
}

void main(){

		fragColor = vec4(GetColor(), 1.0);
}
