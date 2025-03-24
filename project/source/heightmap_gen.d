module heightmap_gen;

//generate a heightmap from perlin noise to get a square grid of height values
//this will be used to generate a terrain mesh
import std.stdio;
import std.math;
import std.random;



struct HeightMap{
    float[][] y_vals;
    int width;
    int height;

    this(int width, int height){
        this.width = width;
        this.height = height;
        this.y_vals = new float[][width]; 
        foreach (ref row; this.y_vals) {
            row = new float[height];
        }

    }
}

HeightMap generateHeightmap(int width, int height, float scale) {
    HeightMap heightmap = HeightMap(width, height);
    foreach (x; 0 .. width) {
        foreach (z; 0 .. height) {
            float nx = x * scale;
            float nz = z * scale;
            heightmap.y_vals[x][z] = perlinNoise(nx, nz)* .5;
        }
    }
    // debugHeightMap(heightmap);
    return heightmap;
}

float perlinNoise(float x, float y) {
    // Simple Perlin noise function
    return (sin(x) + cos(y));
}

void debugHeightMap(HeightMap heightmap){
    writeln("===========================");
    foreach (row; heightmap.y_vals) {
        foreach (value; row) {
            // writef("%f ", value);

            writef("%.3f ", value);
        }
        writeln();
    }
    writeln("===========================");
}
