module perlin;

import linear;
import std.stdio;
import std.math;

//hash funciton to generate random unit vectors
vec2 genRandomVector(int ix, int iy)
{
    //needs to be deterministics as mutliple calls will be made back to repeated vertices
    //look into storing the vectors to improve performacne
    const uint w = 8 * uint.sizeof;
    const uint s = w / 2;
    uint a = ix, b = iy;
    a *= 3284157443;

    b ^= a << s | a >> w - s;
    b *= 1911520717;

    a ^= b << s | b >> w - s;
    a *= 2048419325;
    float random = a * (3.14159265 / ~(~0u >> 1));

    // Create the vector from the angle
    vec2 v;
    v.x = sin(random);
    v.y = cos(random);

    return v;

}

float interpolate(float a, float b, float t)
{
    //cubic interpolation to avoid boxy-like result
    return (b - a) * (3.0 - t * 2.0) * t * t + a;
}

float perlinNoise(float x, float y)
{
    // Simple Perlin noise function using https://www.youtube.com/watch?v=kCIaHqb60Cw
    int x0, x1, y0, y1;
    x0 = cast(int) floor(x);
    x1 = x0 + 1;
    y0 = cast(int) floor(y);
    y1 = y0 + 1;

    //Interpolation Weights
    float sx = x - x0;
    float sy = y - y0;
    // writeln(x0,y0,x1,y1,sx,sy);
    //interpolate the top and bottom corners, then interpolate between the result
    float topLeft = Dot(genRandomVector(x0, y0), vec2(x - x0, y - y0));
    float topRight = Dot(genRandomVector(x1, y0), vec2(x - x1, y - y0));
    float bottomLeft = Dot(genRandomVector(x0, y1), vec2(x - x0, y - y1));
    float bottomRight = Dot(genRandomVector(x1, y1), vec2(x - x1, y - y1));

    float interpTop = interpolate(topLeft, topRight, sx);
    float interpBottom = interpolate(bottomLeft, bottomRight, sx);
    float val = interpolate(interpTop, interpBottom, sy);
    // writeln(val);
    return val;

}
