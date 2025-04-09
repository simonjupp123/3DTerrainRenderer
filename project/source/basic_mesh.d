module basic_mesh;

import std.stdio;
import sdl_abstraction;
import opengl_abstraction;
import bindbc.sdl;
import bindbc.opengl;

GLuint[] InitIndices(int width, int height)
{
    GLuint[] indices;
    for (int i = 0; i < width - 1; i++)
    {
        for (int j = 0; j < height - 1; j++)
        {
            //Triangle 1
            indices ~= i * height + j; //bottom left
            indices ~= i * height + j + 1; //bottom right
            indices ~= (i + 1) * height + j + 1; //top right
            //Triangle 2
            indices ~= i * height + j; //bottom left
            indices ~= (i + 1) * height + j + 1; //top right
            indices ~= (i + 1) * height + j; //top left
        }
    }
    return indices;
}
