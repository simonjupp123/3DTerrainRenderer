#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec2 aTexCoords;

out vec2 vTexCoords;
out vec4 vWorldCoords;


uniform mat4 gVP;


void main()
{
	vTexCoords = aTexCoords;
	vWorldCoords = vec4(aPosition, 1.0f);

	vec4 finalPosition = gVP * vec4(aPosition, 1.0f);

	// Note: Something subtle, but we need to use the finalPosition.w to do the perspective divide
	gl_Position = vec4(finalPosition.x, finalPosition.y, finalPosition.z, finalPosition.w);
}
