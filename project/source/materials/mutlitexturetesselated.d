
module mutlitexturetesselated;

import pipeline, materials, texture;
import bindbc.opengl;

/// Represents a material with multiple textures
class MutliTextureTesselated : IMaterial{
    Texture mTexture1;
    Texture mTexture2;
    Texture mTexture3;
    Texture mTexture4;
    Texture mTexture5;

    /// Construct a new material for a pipeline, and load a texture for that pipeline
    this(string pipelineName, 
            string textureFileName1, 
            string textureFileName2,
            string textureFileName3,
            string textureFileName4,
            string textureFileName5
        ){
        /// delegate to the base constructor to do initialization
        super(pipelineName);

        mTexture1 = new Texture(textureFileName1,256,256);
        mTexture2 = new Texture(textureFileName2,256,256);
        mTexture3 = new Texture(textureFileName3,256,256);
        mTexture4 = new Texture(textureFileName4,256,256);

        mTexture5 = new Texture(textureFileName5,513,513);
    }

    /// TextureMaterial.Update()
    override void Update(){
        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);

        // Set any uniforms for our mesh if they exist in the shader
        if("sampler1" in mUniformMap){
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D,mTexture1.mTextureID);
            mUniformMap["sampler1"].Set(0);
        }
        if("sampler2" in mUniformMap){
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D,mTexture2.mTextureID);
            mUniformMap["sampler2"].Set(1);
        }
        if("sampler3" in mUniformMap){
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D,mTexture3.mTextureID);
            mUniformMap["sampler3"].Set(2);
        }
        if("sampler4" in mUniformMap){
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D,mTexture4.mTextureID);
            mUniformMap["sampler4"].Set(3);
        }
         if("gHeightMap" in mUniformMap){
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(GL_TEXTURE_2D,mTexture5.mTextureID);
            mUniformMap["gHeightMap"].Set(4);
        }
    }
}
