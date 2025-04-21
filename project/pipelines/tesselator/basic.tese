#version 410 core

layout (quads, fractional_odd_spacing, ccw) in;

in vec2 Tex2[];

out vec2 Tex3;
out float Height;

uniform sampler2D gHeightMap;
uniform mat4 gVP;

void main()
{
    // get the results from the tessellator
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;

    // get the texture coordinate for each vertex
    vec2 t00 = Tex2[0];     // bottom left
    vec2 t01 = Tex2[1];     // bottom right
    vec2 t10 = Tex2[2];     // top left
    vec2 t11 = Tex2[3];     // top right

    vec2 t0 = (t01 - t00) * u + t00;    // interpolate bottom
    vec2 t1 = (t11 - t10) * u + t10;    // interpolate top
    Tex3 = (t1 - t0) * v + t0;          // final interpolation

    // sample the height from the height map
    Height = (texture(gHeightMap, Tex3).r * 255.0f) * (30) / (255) - 18;   

    // get the position for each vertex
    vec4 p00 = gl_in[0].gl_Position;
    vec4 p01 = gl_in[1].gl_Position;
    vec4 p10 = gl_in[2].gl_Position;
    vec4 p11 = gl_in[3].gl_Position;

    // same interpolation as the previous one
    vec4 p0 = (p01 - p00) * u + p00;
    vec4 p1 = (p11 - p10) * u + p10;
    vec4 p = (p1 - p0) * v + p0;
    
    p.y += Height ;  // add the sampled height

    // transform from world to clip space
    gl_Position = gVP * p;
}