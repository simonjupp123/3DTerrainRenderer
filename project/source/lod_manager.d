module lod_manager;

import linear;
import std.stdio;

struct PatchLodInfo
{
    int left = 0;
    int right = 0;
    int top = 0;
    int bottom = 0;
    int core = 0;
}

class LodManager
{
    // PatchLodInfo[] m_map; // equal to size of 
    PatchLodInfo[][] m_map2D;
    int m_patch_size;
    int m_num_patches_x;
    int m_num_patches_z;

    void InitLodManager(int patch_size, int num_patches_x, int num_patches_z)
    {   
        //1D 
        // m_map.length = num_patches_x * num_patches_z;
        // for (int i = 0; i < m_map.length; i++)
        // {
        //     PatchLodInfo e;
        //     m_map[i] = e;
        // }
        //2d 
        for (int i = 0; i < num_patches_z; i++)
        {
            PatchLodInfo[] row;
            row.length = num_patches_x;
            for (int j = 0; j < num_patches_x; j++)
            {
                PatchLodInfo e;
                row[j] = e;
            }
            m_map2D ~= row;
        }
        m_patch_size = patch_size;
        m_num_patches_x = num_patches_x;
        m_num_patches_z = num_patches_z;
    }

    PatchLodInfo getPatchInfo(int patch_x, int patch_z)
    {
        //returns patch info
        // PatchLodInfo plod;
        // plod.left =
        // plod.right =
        // plod.bottom =
        // plod.top =
        // plod.core
        //2d
        return m_map2D[patch_z][patch_x];
        //1D
        //return m_map[(patch_z * m_num_patches_x) + patch_x];
    }

    void update(vec3 camera_pos)
    {
        //two pass approach, first update all cores, then update edges (we dont know an edge res until we know all cores)

        //first pass: update cores:
        int centerStep = m_patch_size / 2;
        for (int patch_z = 0; patch_z < m_num_patches_z; patch_z++)
        {
            for (int patch_x = 0; patch_x < m_num_patches_x; patch_x++)
            {
                float patch_x_center = patch_x * m_patch_size + centerStep; //TODO, COME BACK TO THIS, WILL NOT WORK WITHOUT WORLD SCALE IN LONG RUN/ PAYING ATTENTION TO HARDCODED heightmap
                float patch_z_center = patch_z * m_patch_size + centerStep;
                vec3 patch_center = vec3(patch_x_center, 0.0f, patch_z_center); //FIX y VALUE
                float dist = Distance(camera_pos, patch_center);
                //Todo fix this:
                int coreLod = 4;
                // writeln(dist);
                if (dist < 500)
                {
                    coreLod = 3;
                }
                else if (dist < 350)
                {
                    coreLod = 2;
                }
                else if (dist < 200)
                {
                    coreLod = 1;
                }
                else if (dist < 100)
                {
                    coreLod = 0;
                }
                // m_map[(patch_z * m_num_patches_x) + patch_x].core = coreLod;
                m_map2D[patch_z][patch_x].core = coreLod;
                // pInfo.core = coreLod;

            }
        }

        //second pass for edges
        for (int patch_z = 0; patch_z < m_num_patches_z; patch_z++)
        {
            for (int patch_x = 0; patch_x < m_num_patches_x; patch_x++)
            {
                // PatchLodInfo pInfo = m_map[(patch_z * m_num_patches_x) + patch_x];
                PatchLodInfo pInfo = m_map2D[patch_z][patch_x];
                //update all 4 sides

                // int leftInd = (patch_z * m_num_patches_x) + patch_x - 1;
                
                // int rightInd = (patch_z * m_num_patches_x) + patch_x + 1;
                // int topInd = (patch_z * (m_num_patches_x + 1)) + patch_x;
                // int bottomInd = (patch_z * (m_num_patches_x - 1)) + patch_x;
                int leftInd = patch_x - 1;
                int rightInd = patch_x + 1;
                int topInd = patch_z + 1;
                int bottomInd = patch_z - 1;

                //if we assume all are valid
                int leftCore = leftInd >= 0 ? m_map2D[patch_z][leftInd].core : -1;
                // writeln(rightInd);
                // writeln(patch_z);
                // writeln(m_map2D[patch_z].length);
                int rightCore = rightInd < m_num_patches_x ? m_map2D[patch_z][rightInd].core : -1;
                int topCore = topInd < m_num_patches_z ? m_map2D[topInd][patch_x].core : -1;
                int bottomCore = bottomInd >= 0 ? m_map2D[bottomInd][patch_x].core : -1;

                if (leftCore > pInfo.core)
                {
                     m_map2D[patch_z][patch_x].left = 1;
                }
                else
                {
                     m_map2D[patch_z][patch_x].left = 0;
                }

                if (rightCore > pInfo.core)
                {
                     m_map2D[patch_z][patch_x].right = 1;
                }
                else
                {
                     m_map2D[patch_z][patch_x].right = 0;
                }

                if (topCore > pInfo.core)
                {
                     m_map2D[patch_z][patch_x].top = 1;
                }
                else
                {
                     m_map2D[patch_z][patch_x].top = 0;
                }

                if (bottomCore > pInfo.core)
                {
                     m_map2D[patch_z][patch_x].bottom = 1;
                }
                else
                {
                     m_map2D[patch_z][patch_x].bottom = 0;
                }
            }
        }
    }
}
