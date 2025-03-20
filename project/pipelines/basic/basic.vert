#version 410 core

layout(location=0) in vec3 position;
layout(location=1) in vec3 vertexColors;

out vec3 v_vertexColors;

uniform mat4 uView;
uniform mat4 uProjection;

void main() {
    v_vertexColors = vertexColors;
    gl_Position = uProjection * uView * vec4(position, 1.0);
}

