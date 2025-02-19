module obj_parser;

import std.stdio;
import sdl_abstraction;
import opengl_abstraction;
import bindbc.sdl;
import bindbc.opengl;
import std.string;
import std.conv;
import std.algorithm;
import std.array;

struct OBJModel{
    GLfloat[] vertices;
    GLfloat[] vertex_normals;
    GLuint[] faces;
}

OBJModel ParseObjFile(string obj_file){
    import std.file;
    string obj_data = readText(obj_file);
    auto lines = obj_data.splitLines();
    // Initialize the OBJModel
    OBJModel o;
    o.vertices = [];
    o.vertex_normals = [];
    o.faces = [];

    foreach(line; lines){
        if(line.startsWith("v ")){
            // Parse vertex data
            auto verts = line.split(" ")[1..$].map!(to!GLfloat).array;
            assert(verts.length == 3);
            o.vertices ~= verts;
            //TODO check if this makes 2D array
        } else if(line.startsWith("vn ")){
            auto vert_normals = line.split(" ")[1..$].map!(to!GLfloat).array;
            assert(vert_normals.length == 3);
            o.vertex_normals ~= vert_normals;
           
        } else if(line.startsWith("f ")){
            auto face_data_raw = line.split(" ")[1..$]; // will be in the form of int//int
            // assert (face_data_raw.length == 3);
            foreach(e; face_data_raw){
                auto face_data = e.split("/");
                // assert(face_data.length >= 2);
                o.faces ~= face_data[0].to!GLuint - 1;
                // o.faces ~= face_data[1].to!GLuint - 1;
            }
            
            //if we are reading in vertex,color... then should be fine for indexing this way

        }
    }
 
    
    return o;
}
// void main  (string[] args)
// {
//     auto model = ParseObjFile(args[1]);
//     writeln(model.vertices.length);
//     // writeln(model.vertex_normals);
//     writeln(model.faces[0..10]);
// }