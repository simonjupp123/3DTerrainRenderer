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
    PatchLodInfo[] m_map; // equal to size of 
    int m_patch_size;
    int m_num_patches_x;
    int m_num_patches_z;

    void InitLodManager(int patch_size, int num_patches_x, int num_patches_z)
    {
        m_map.length = num_patches_x * num_patches_z;
        for (int i = 0; i < m_map.length; i++)
        {
            PatchLodInfo e;
            m_map[i] = e;
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

        return m_map[(patch_z * m_num_patches_x) + patch_x];
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
                m_map[(patch_z * m_num_patches_x) + patch_x].core = coreLod;
                // pInfo.core = coreLod;

            }
        }

        //second pass for edges
        for (int patch_z = 0; patch_z < m_num_patches_z; patch_z++)
        {
            for (int patch_x = 0; patch_x < m_num_patches_x; patch_x++)
            {
                PatchLodInfo pInfo = m_map[(patch_z * m_num_patches_x) + patch_x];
                //update all 4 sides

                int leftInd = (patch_z * m_num_patches_x) + patch_x - 1;
                int rightInd = (patch_z * m_num_patches_x) + patch_x + 1;
                int topInd = (patch_z * (m_num_patches_x + 1)) + patch_x;
                int bottomInd = (patch_z * (m_num_patches_x - 1)) + patch_x;

                //if we assume all are valid
                int leftCore = leftInd > 0 ? m_map[leftInd].core : -1;
                int rightCore = rightInd < m_map.length ? m_map[rightInd].core : -1;
                int topCore = topInd < m_map.length ? m_map[topInd].core : -1;
                int bottomCore = bottomInd > 0 ? m_map[bottomInd].core : -1;

                if (leftCore > pInfo.core)
                {
                    pInfo.left = 1;
                }
                else
                {
                    pInfo.left = 0;
                }

                if (rightCore > pInfo.core)
                {
                    pInfo.right = 1;
                }
                else
                {
                    pInfo.right = 0;
                }

                if (topCore > pInfo.core)
                {
                    pInfo.top = 1;
                }
                else
                {
                    pInfo.top = 0;
                }

                if (bottomCore > pInfo.core)
                {
                    pInfo.bottom = 1;
                }
                else
                {
                    pInfo.bottom = 0;
                }
            }
        }
    }
}
