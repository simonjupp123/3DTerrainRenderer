module heightmap_gen;

//generate a heightmap from perlin noise to get a square grid of height values
//this will be used to generate a terrain mesh
import std.stdio;
import std.math;
import std.random;
import perlin;
import std.algorithm;

struct HeightMap
{
    float[][] y_vals;
    int width;
    int height;

    this(int width, int height)
    {
        this.width = width;
        this.height = height;
        this.y_vals = new float[][width];
        foreach (ref row; this.y_vals)
        {
            row = new float[height];
        }

    }
}

HeightMap generateHeightmap(int width, int height, float scale, int offsetX, int offsetZ)
{
    const int GRID_SIZE = 150;
    //scale is used to control how spread out our vertices
    HeightMap heightmap = HeightMap(width, height);
    float min_val = 10.0f;
    float max_val = 0.0f;
    foreach (x; 0 .. width)
    {
        foreach (z; 0 .. height)
        {
            float nx = (x + offsetX) * scale;
            float nz = (z + offsetZ) * scale;
            float val = 0.0f;
            for (int i = 0; i < 10; i++)
            {
                //this will add multiple layers of noise to create a more complex terrain
                //each layer will have a different scale and amplitude
                float frequency = pow(2.0f, cast(float) i);
                float amplitude = 20 * pow(0.5f, cast(float) i);
                val += perlinNoise(nx * frequency / GRID_SIZE, nz * frequency / GRID_SIZE) * amplitude;
            }
            heightmap.y_vals[x][z] = val * 1.5; //height scalin
            // writeln(perlinNoise(nx, nz));
            if (val > max_val)
            {
                max_val = val;
            }
            if (val < min_val)
            {
                min_val = val;
            }
        }
    }
    saveHeightMapToPPM(heightmap, "./assets/heightmap.ppm");
    writefln("Heightmap generated with min value: %.2f, max value: %.2f", min_val, max_val);
    // debugHeightMap(heightmap);

    return heightmap;
}

void saveHeightMapToPPM(HeightMap heightmap, string filename)
{
    // Open the file for writing
    File file = File(filename, "w");

    // Write the PPM header
    file.writefln("P3");
    file.writefln("%d %d", heightmap.width, heightmap.height);
    file.writefln("255");

    // Normalize height values and write pixel data
    foreach (z; 0 .. heightmap.height)
    {
        foreach (x; 0 .. heightmap.width)
        {
            float height = heightmap.y_vals[x][z];

            // Normalize the height to a range of 0-255
            // int grayscale = cast(int)(height) + 32;
            // int grayscale = cast(int) clamp(height, 0.0f, 255.0f);
            int grayscale = cast(int)(height + 18) * (255) / (30);
            // int grayscale = cast(int) height;
            grayscale = clamp(grayscale, 0, 255);

            // Write the grayscale value as RGB (R=G=B for grayscale)
            file.writefln("%d", grayscale);
            file.writefln("%d", grayscale);
            file.writefln("%d", grayscale);
        }
    }

    file.close();
    writeln("Heightmap saved to ", filename);
}

void debugHeightMap(HeightMap heightmap)
{
    writeln("===========================");
    foreach (row; heightmap.y_vals)
    {
        foreach (value; row)
        {
            // writef("%f ", value);

            writef("%.3f ", value);
        }
        writeln();
    }
    writeln("===========================");
}
