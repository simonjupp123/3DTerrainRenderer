module heightmap_gen;

//generate a heightmap from perlin noise to get a square grid of height values
//this will be used to generate a terrain mesh
import std.stdio;
import std.math;
import std.random;
import perlin;



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
    //scale is used to control how spread out our vertices
    HeightMap heightmap = HeightMap(width, height);
    foreach (x; 0 .. width) {
        foreach (z; 0 .. height) {
            float nx = x * scale;
            float nz = z * scale;
            float val = 0.0f;
            for(int i = 0; i < 2; i++){
                //this will add multiple layers of noise to create a more complex terrain
                //each layer will have a different scale and amplitude
                float frequency = pow(2.0f, cast(float)i);
                float amplitude = pow(0.5f, cast(float)i);
                val += perlinNoise(nx * frequency/ 50, nz * frequency/50) * amplitude;
            }
            heightmap.y_vals[x][z] =val * 1.1; //height scalin
            // writeln(perlinNoise(nx, nz));
        }
    }
    debugHeightMap(heightmap);

    return heightmap;
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
