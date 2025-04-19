#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec2 aTexCoords;
layout(location=2) in vec3 aNormal;

out vec2 vTexCoords;
out vec4 vWorldCoords;
out vec3 vNormal;


uniform mat4 gVP;


void main()
{
	vTexCoords = aTexCoords;
	vNormal = aNormal;
	vWorldCoords = vec4(aPosition, 1.0f);

	vec4 finalPosition = gVP * vec4(aPosition, 1.0f);

	// Note: Something subtle, but we need to use the finalPosition.w to do the perspective divide
	gl_Position = vec4(finalPosition.x, finalPosition.y, finalPosition.z, finalPosition.w);
}
