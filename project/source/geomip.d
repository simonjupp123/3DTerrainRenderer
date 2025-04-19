module geomip;

import std.stdio;
import std.math;
import sdl_abstraction;
import opengl_abstraction;
import bindbc.sdl;
import bindbc.opengl;

import linear;
import lod_manager;
import vertex_info;

const m_patchsize = 33; //TODO
const m_width = 513;
const m_height = 513;

const int m_Xpatches = (m_width - 1) / (m_patchsize - 1);
const int m_Zpatches = (m_height - 1) / (m_patchsize - 1);

const MAX_LOD = 5;

LodInfo[] m_lodInfo;

struct SingleLodInfo
{
    int start = 0;
    int count = 0;
};

struct LodInfo
{
    SingleLodInfo[2][2][2][2] info;
};

LodManager m_lodManager;

GLuint[] GeomipInitIndices(int width, int height, int patch_size)
{
    writeln(m_Xpatches);
    writeln(m_Zpatches);
    m_lodInfo.length = MAX_LOD;
    GLuint[] indices;
    int index = 0;
    m_lodManager = new LodManager();
    m_lodManager.InitLodManager(m_patchsize, m_Xpatches, m_Zpatches);

    // const temp_resize = 400; //TODO FIND THE ACTUAL SIZE OF THE BUFFER AND RESIZE 
    //determine number of indices first to resize buffer
    indices.length = CalcMaxIndices();
    for (int i = 0; i < MAX_LOD; i++)
    {
        index = InitInicidesLOD(index, indices, i);
    }

    return indices;
}

int CalcMaxIndices()
{
    int NumQuads = (m_patchsize - 1) * (m_patchsize - 1);
    int NumIndices = 0;
    int MaxPermutationsPerLevel = 16;
    const int IndicesPerQuad = 6;
    for (int lod = 0; lod <= MAX_LOD; lod++)
    {
        NumIndices += NumQuads * IndicesPerQuad * MaxPermutationsPerLevel;
        NumQuads /= 4;
    }
    return NumIndices;
}

int InitInicidesLOD(int ind, GLuint[] indices, int lod)
{
    //initialize for all possible LOD combinations
    const PERMUTATION = 2;
    for (int l = 0; l < PERMUTATION; l++)
    {
        for (int r = 0; r < PERMUTATION; r++)
        {
            for (int t = 0; t < PERMUTATION; t++)
            {
                for (int b = 0; b < PERMUTATION; b++)
                {
                    m_lodInfo[lod].info[l][r][t][b].start = ind;

                    //requires more management for LOD start and count
                    ind = InitIndicesSingle(ind, indices, lod, lod + l, lod + r, lod + t, lod + b);
                    m_lodInfo[lod].info[l][r][t][b].count = ind - m_lodInfo[lod]
                        .info[l][r][t][b].start;
                }
            }
        }
    }
    return ind;
}

int InitIndicesSingle(int ind, GLuint[] indices, int lod, int lodLeft, int lodRight, int lodTop, int lodBottom)
{
    int fan_step = pow(2, lod + 1);
    int end_pos = m_patchsize - 1 - fan_step;
    for (int z = 0; z <= end_pos; z += fan_step)
    {
        for (int x = 0; x <= end_pos; x += fan_step)
        {
            //need to consider edge cases to handle cracks. 
            // check if we are on the boundaries points for a single patch, and then set edges to respective l,r,t,b
            int l = x == 0 ? lodLeft : lod;
            int r = x == end_pos ? lodRight : lod;
            int b = z == 0 ? lodBottom : lod;
            int t = z == end_pos ? lodTop : lod;

            ind = CreateTriangleFan(ind, indices, lod, l, r, t, b, x, z);
        }
    }
    return ind;

}

int CreateTriangleFan(int ind, GLuint[] indices, int lodCore, int lodLeft, int lodRight, int lodTop, int lodBottom, int x, int z)
{
    int StepLeft = pow(2, lodLeft);
    int StepRight = pow(2, lodRight);
    int StepTop = pow(2, lodTop);
    int StepBottom = pow(2, lodBottom);
    int StepCore = pow(2, lodCore);
    int centerInd = (z + StepCore) * m_width + x + StepCore;

    //Important here to maintain winding order, center index will never be changing, index1 always equals ind2 after an update
    int index1 = z * m_width + x;
    int index2 = (z + StepLeft) * m_width + x;

    //left side triangles
    ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    if (lodCore == lodLeft)
    {
        index1 = index2;
        index2 = index2 + (StepLeft * m_width);
        ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    }
    //top side triangles
    index1 = index2;
    index2 = index2 + StepTop;
    ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    if (lodCore == lodTop)
    {
        index1 = index2;
        index2 = index2 + StepTop;
        ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    }
    //right side triangles
    index1 = index2;
    index2 = index2 - (m_width * StepRight);
    ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    if (lodCore == lodRight)
    {
        index1 = index2;
        index2 = index2 - (m_width * StepRight);
        ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    }
    //bottom side triangles
    index1 = index2;
    index2 = index2 - StepBottom;
    ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    if (lodCore == lodBottom)
    {
        index1 = index2;
        index2 = index2 - StepBottom;
        ind = CreateTriangle(ind, indices, centerInd, index1, index2);
    }

    return ind;

}

int CreateTriangle(int ind, GLuint[] indices, int ind1, int ind2, int ind3)
{
    indices[ind++] = cast(uint) ind1;
    indices[ind++] = cast(uint) ind2;
    indices[ind++] = cast(uint) ind3;
    return ind;
}

void RenderGeo(vec3 camera_pos)
{
    //iterate over each patch and render

    m_lodManager.update(camera_pos);
    for (int patch_z = 0; patch_z < m_Zpatches; patch_z++)
    {
        for (int patch_x = 0; patch_x < m_Xpatches; patch_x++)
        {
            // Todo. use camera to get actual l,r,t,b,core for current patch
            PatchLodInfo pInfo = m_lodManager.getPatchInfo(patch_x, patch_z);
            // writeln(pInfo);
            int l = pInfo.left;
            int r = pInfo.right;
            int t = pInfo.top;
            int b = pInfo.bottom;
            int core = pInfo.core;
            // if (core != 0)
            // {
            //     writeln(core);
            // }
            size_t baseInd = uint.sizeof * m_lodInfo[core].info[l][r][t][b].start;
            int baseVert = (patch_z * (m_patchsize - 1)) * m_width + (patch_x * (m_patchsize - 1));
            glDrawElementsBaseVertex(GL_TRIANGLES, m_lodInfo[core].info[l][r][t][b].count, GL_UNSIGNED_INT, cast(
                    void*) baseInd, baseVert);
        }
    }

}

void GeomipCalculateNormals(ref VertexData[] vertexDataArray, GLuint[] Indices)
{
    uint Index = 0;

    // Accumulate each triangle normal into each of the triangle vertices
    for (int z = 0; z < m_height - 1; z += (m_patchsize - 1))
    {
        for (int x = 0; x < m_width - 1; x += (m_patchsize - 1))
        {
            int BaseVertex = z * m_width + x;
            //printf("Base index %d\n", BaseVertex);
            int NumIndices = m_lodInfo[0].info[0][0][0][0].count;
            for (int i = 0; i < NumIndices; i += 3)
            {
                uint Index0 = BaseVertex + Indices[i];
                uint Index1 = BaseVertex + Indices[i + 1];
                uint Index2 = BaseVertex + Indices[i + 2];
                vec3 v1 = vertexDataArray[Index1].vertices - vertexDataArray[Index0].vertices;
                vec3 v2 = vertexDataArray[Index2].vertices - vertexDataArray[Index0].vertices;
                vec3 Normal = v1.Cross(v2);
                Normal = Normal.Normalize();

                // vertexDataArray[Index0].normals += Normal;
                // vertexDataArray[Index1].normals += Normal;
                // vertexDataArray[Index2].normals += Normal;
                vertexDataArray[Index0].normals = vertexDataArray[Index0].normals + Normal;
                vertexDataArray[Index1].normals = vertexDataArray[Index1].normals + Normal;
                vertexDataArray[Index2].normals = vertexDataArray[Index2].normals + Normal;
            }
        }
    }

    // Normalize all the vertex normals
    // for (uint i = 0; i < Vertices.size(); i++)
    // {
    //     Vertices[i].Normal.Normalize();
    // }
    foreach (ref vertex; vertexDataArray)
    {
        // writeln(Normalize(vertex.normals));
        vertex.normals = Normalize(vertex.normals);
    }
}
