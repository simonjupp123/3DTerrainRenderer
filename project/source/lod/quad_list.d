module quad_list;

import lod;

import opengl_abstraction;

import bindbc.opengl;
import linear;
import vertex_info;

class QuadList : LODMethod{
    int mOffsetX = 0;
    int mOffsetZ = 0;
    int m_width;
    int m_depth;

    this(int offsetX, int offsetZ, int width, int depth)
    {
        mOffsetX = offsetX;
        mOffsetZ = offsetZ;
        m_width = width;
        m_depth = depth;
        
    }
    

    override void Render(vec3 pos){
        // import std.stdio;
        // writeln("rendering");
        glPatchParameteri(GL_PATCH_VERTICES, 4);
        glDrawElements(GL_PATCHES, (m_depth - 1) * (m_width - 1) * 4, GL_UNSIGNED_INT, null);
        // glDrawArrays(GL_PATCHES, 0, 4*(m_depth - 1)*(m_width - 1));

    }
    override void InitIndices(ref GLuint[] indices)
    {
        int Index = 0;

        for (int z = 0 ; z < m_depth - 1 ; z++) {
            for (int x = 0 ; x < m_width - 1 ; x++) {												
              
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

    void InitVertices(ref GLfloat[] mVertexData, VertexData[] vertexDataArray){
        float worldScale = 1.0f; //could be a problem TODO (WITH ORDER OF ADDING OFFSET then multing by worldScale)
        float textureScale = 1.0f;
        foreach (vertex; vertexDataArray)
        {
            // Add vertex position
            mVertexData ~= vertex.vertices.x * worldScale;
            // mVertexData ~= vertex.vertices.y;
            mVertexData ~= 0;
            mVertexData ~= vertex.vertices.z * worldScale;

            // Add texture coordinates
            mVertexData ~= vertex.texCoords.x * textureScale/ m_width;
            mVertexData ~= vertex.texCoords.y * textureScale/ m_depth;

            // mVertexData ~= vertex.normals.x;
            // mVertexData ~= vertex.normals.y;
            // mVertexData ~= vertex.normals.z;
        }
    }
    
}
