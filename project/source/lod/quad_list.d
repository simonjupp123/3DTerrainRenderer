module quad_list;

import lod;

import opengl_abstraction;

import bindbc.opengl;
import linear;
import vertex_info;

class QuadList : LODMethod
{
    int mOffsetX = 0;
    int mOffsetZ = 0;
    int m_width;
    int m_depth;
    int rez = 10;

    this(int offsetX, int offsetZ, int width, int depth)
    {
        mOffsetX = offsetX;
        mOffsetZ = offsetZ;
        m_width = width;
        m_depth = depth;

    }

    override void Render(vec3 pos)
    {
        // import std.stdio;
        // writeln("rendering");
        glPatchParameteri(GL_PATCH_VERTICES, 4);
        // glDrawElements(GL_PATCHES, (m_depth - 1) * (m_width - 1) * 4, GL_UNSIGNED_INT, null);
        glDrawArrays(GL_PATCHES, 0, 4*rez*rez);
        // glDrawArrays(GL_PATCHES, 0, 4*(m_depth - 1)*(m_width - 1));

    }

    override void InitIndices(ref GLuint[] indices)
    {
        int Index = 0;

        for (int z = 0; z < m_depth - 1; z++)
        {
            for (int x = 0; x < m_width - 1; x++)
            {

                uint IndexBottomLeft = z * m_width + x;
                indices ~= IndexBottomLeft;

                uint IndexBottomRight = z * m_width + x + 1;
                indices ~= IndexBottomRight;

                uint IndexTopLeft = (z + 1) * m_width + x;
                indices ~= IndexTopLeft;

                uint IndexTopRight = (z + 1) * m_width + x + 1;
                indices ~= IndexTopRight;
            }
        }

    }

    void InitVertices(ref GLfloat[] mVertexData, VertexData[] vertexDataArray)
    {
        // float worldScale = 10.0f; // scale the the x,z positions by a certain ratio
        // float textureScale = 8.0f; // scale the texture coordinates based on the width of the terrain, generally this should be the same as the world scale
        // foreach (vertex; vertexDataArray)
        // {
        //     // Add vertex position
        //     mVertexData ~= vertex.vertices.x * worldScale;
        //     // mVertexData ~= vertex.vertices.y;
        //     mVertexData ~= 0.0f; // We are rendering a flat terrain, so y is always 0
        //     mVertexData ~= vertex.vertices.z * worldScale;

        //     // Add texture coordinates
        //     mVertexData ~= vertex.texCoords.x * textureScale / m_width;
        //     mVertexData ~= vertex.texCoords.y * textureScale / m_depth;

        //     // mVertexData ~= vertex.normals.x;
        //     // mVertexData ~= vertex.normals.y;
        //     // mVertexData ~= vertex.normals.z;
        // }
        int width = 1024;
        int height = 1024;
        float tex_scale = 512.0f/width;
        
        for(int i = 0; i <= rez-1; i++)
        {
            for(int j = 0; j <= rez-1; j++)
            {
                mVertexData ~= -width/2.0f + width*i/ cast(float)rez; // v.x
                mVertexData ~= 0.0f; // v.y
                mVertexData ~= -height/2.0f + height*j/cast(float)rez; // v.z
                mVertexData ~= i / cast(float)rez /tex_scale; // u
                mVertexData ~= j / cast(float)rez/tex_scale; // v

                 mVertexData ~= -width/2.0f + width*(i+1)/ cast(float)rez; // v.x
                mVertexData ~= 0.0f; // v.
                mVertexData ~= -height/2.0f + height*j/cast(float)rez; // v.z
                mVertexData ~= (i+1) / cast(float)rez/tex_scale; // u
                mVertexData ~= j / cast(float)rez/tex_scale; // v

                mVertexData ~= -width/2.0f + width*i/ cast(float)rez; // v.x
                mVertexData ~= 0.0f; // v.y
                mVertexData ~= -height/2.0f + height*(j+1)/cast(float)rez; // v.z
                mVertexData ~= i / cast(float)rez/tex_scale; // u
                mVertexData ~= (j+1)/ cast(float)rez/tex_scale; // v

               

                mVertexData ~= -width/2.0f + width*(i+1)/ cast(float)rez; // v.x
                mVertexData ~= 0.0f; // v.y
                mVertexData ~= -height/2.0f + height*(j+1)/cast(float)rez; // v.z
                mVertexData ~= (i+1) / cast(float)rez/tex_scale; // u
                mVertexData ~= (j+1) / cast(float)rez/tex_scale; // v

                
            }
        }
    }

}
