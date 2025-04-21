module lod_method;

import linear;

import opengl_abstraction;

import bindbc.opengl;

abstract class LODMethod{


    void InitIndices(){
    }
    void InitIndices(ref GLuint[] indices){
    }

  
    void Render(vec3 pos){

    }
}