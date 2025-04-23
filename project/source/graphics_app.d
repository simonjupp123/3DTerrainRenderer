import std.stdio;
import sdl_abstraction;
import opengl_abstraction;
import bindbc.sdl;
import bindbc.opengl;

import std.string;
import std.conv;
import std.algorithm;

import obj_parser;
import heightmap_gen;
import camera_ogldev;
import linear;
import basic_mesh;
import geomip;
import pipeline;
import materials;
import uniform;
import vertex_info;
import lod;

/// Create a basic shader
/// The result is a 'GLuint' representing the compiled 'program object' or otherwise 'graphics pipeline'
/// that is compiled and ready to execute on the GPU.
GLuint BuildBasicShader(string vertexShaderSourceFilename, string fragmentShaderSourceFilename)
{

    // Local nested function -- not meant for otherwise calling freely
    void CheckShaderError(GLuint shaderObject)
    {
        // Retrieve the result of our compilation
        int result;
        // Our goal with glGetShaderiv is to retrieve the compilation status
        glGetShaderiv(shaderObject, GL_COMPILE_STATUS, &result);

        if (result == GL_FALSE)
        {
            int length;
            glGetShaderiv(shaderObject, GL_INFO_LOG_LENGTH, &length);
            GLchar[] errorMessages = new GLchar[length];
            glGetShaderInfoLog(shaderObject, length, &length, errorMessages.ptr);
            writeln("Shader Compilation Error: ", errorMessages);
        }

    }

    import std.file;

    GLuint programObjectID;

    // Compile our shaders
    GLuint vertexShader;
    GLuint fragmentShader;

    // Use a string mixin to simply 'load' the text from a file into these
    // strings that will otherwise be processed.
    string vertexSource = readText(vertexShaderSourceFilename);
    string fragmentSource = readText(fragmentShaderSourceFilename);

    // Compile vertex shader
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char* vertSource = vertexSource.ptr;
    glShaderSource(vertexShader, 1, &vertSource, null);
    glCompileShader(vertexShader);
    CheckShaderError(vertexShader);

    // Compile fragment shader
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    const char* fragSource = fragmentSource.ptr;
    glShaderSource(fragmentShader, 1, &fragSource, null);
    glCompileShader(fragmentShader);
    CheckShaderError(fragmentShader);

    // Create shader pipeline
    programObjectID = glCreateProgram();

    // Link our two shader programs together.
    // Consider this the equivalent of taking two .cpp files, and linking them into
    // one executable file.
    glAttachShader(programObjectID, vertexShader);
    glAttachShader(programObjectID, fragmentShader);
    glLinkProgram(programObjectID);

    // Validate our program
    glValidateProgram(programObjectID);

    // Once our final program Object has been created, we can
    // detach and then delete our individual shaders.
    glDetachShader(programObjectID, vertexShader);
    glDetachShader(programObjectID, fragmentShader);
    // Delete the individual shaders once we are done
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    PrintProgram(programObjectID);
    return programObjectID;
}

void PrintProgram(GLuint programID)
{
    writeln("------- Shader Information --------");
    GLint num_uniforms;
    glGetProgramiv(programID, GL_ACTIVE_UNIFORMS, &num_uniforms);
    GLchar[256] uniform_name;
    GLsizei length;
    GLint size;
    GLenum type;
    for (int i = 0; i < num_uniforms; i++)
    {
        glGetActiveUniform(programID, i, 256, &length, &size, &type, uniform_name.ptr);
        printf("#%i name: %.*s\n", i, length, uniform_name.ptr);
    }
}

struct Mesh
{
    GLuint mVAO;
    GLuint mVBO;
    GLuint mIBO;
    int mNumIndices;
    IMaterial mMaterial;
    GeomipManager mGeomipManager;
    QuadList mQuadList;
    LODMethod mLODMethod;

}

// struct VertexData
// {
//     vec3 vertices;
//     vec3 normals;
//     vec2 texCoords;
// }

void CalculateNormals(ref VertexData[] vertexDataArray, GLuint[] indices)
{ // Calculate normals for each vertex based on the indices

    for (size_t i = 0; i < indices.length; i += 3)
    {
        // Get the indices of the triangle vertices
        GLuint index1 = indices[i];
        GLuint index2 = indices[i + 1];
        GLuint index3 = indices[i + 2];

        // Get the vertices of the triangle
        vec3 v1 = vertexDataArray[index1].vertices;
        vec3 v2 = vertexDataArray[index2].vertices;
        vec3 v3 = vertexDataArray[index3].vertices;

        // Calculate the normal using cross product
        vec3 edge1 = v2 - v1;
        vec3 edge2 = v3 - v1;

        vec3 normal = Normalize(Cross(edge1, edge2));

        // Add the normal to each vertex of the triangle
        vertexDataArray[index1].normals = vertexDataArray[index1].normals + normal;
        vertexDataArray[index2].normals = vertexDataArray[index2].normals + normal;
        vertexDataArray[index3].normals = vertexDataArray[index3].normals + normal;
    }

    // Normalize the normals for each vertex
    foreach (ref vertex; vertexDataArray)
    {
        // writeln(Normalize(vertex.normals));
        vertex.normals = Normalize(vertex.normals);
    }
}

//Function to create our quadmap from our heightmap generator
Mesh MakeMeshFromHeightmap(HeightMap heightmap, int offsetX, int offsetZ)
{
    Mesh m;

    // Initialize VBO and IBO

    GLfloat[] mVertexData = [];
    VertexData[] vertexDataArray = [];

    writeln("VertexDataArray length: ", vertexDataArray.length);

    if (mMode == "GEOMIP")
    {
        for (int i = 0; i < heightmap.width; i++)
        {
            for (int j = 0; j < heightmap.height; j++)
            {
                VertexData vertexData;
                vertexData.vertices = vec3(i + offsetX, heightmap.y_vals[i][j], j + offsetZ);
                vertexData.normals = vec3(0.0f, 0.0f, 0.0f); //TODO: calculate normals
                vertexData.texCoords = vec2(i, j);
                vertexDataArray ~= vertexData;
            }
        }
        int patch_size = 3;
        GeomipManager geomipManager = new GeomipManager(offsetX, offsetZ);
        // geomipManager.GeomipInitIndices(heightmap.width, heightmap.height, patch_size);
        GLuint[] mIndices = geomipManager.mIndices;

        //only after initializing indices can we calc normals:
        //CalculateNormals(vertexDataArray, mIndices);// this would work without geomip
        geomipManager.GeomipCalculateNormals(vertexDataArray, mIndices);
        m.mGeomipManager = geomipManager;
        m.mLODMethod = geomipManager;
        m.mGeomipManager.PopulateVBO(mVertexData, vertexDataArray);

        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &m.mVAO);
        glBindVertexArray(m.mVAO);

        // Vertex Buffer Object (VBO) creation
        glGenBuffers(1, &m.mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, m.mVBO);
        glBufferData(GL_ARRAY_BUFFER, mVertexData.length * GLfloat.sizeof, mVertexData.ptr, GL_STATIC_DRAW);

        //Index Buffer to increase efficiency
        glGenBuffers(1, &m.mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mIndices.length * GLuint.sizeof, mIndices.ptr, GL_STATIC_DRAW);

        //positions
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 8, cast(void*) 0);

        //Textures instead
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 8, cast(GLvoid*)(
                GLfloat.sizeof * 3));

        // normals
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 8, cast(GLvoid*)(
                GLfloat.sizeof * 5));

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);
        // Disable any attributes we opened in our Vertex Attribute Array,
        // as we do not want to leave them open. 
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(2);
    }
    else if (mMode == "QUAD")
    {
        int n_patches = 500; //DETERMINES HOW BIG THE PATCH WILL BE
        for (int i = 0; i < n_patches; i++)
        {
            for (int j = 0; j < n_patches; j++)
            {
                VertexData vertexData;
                vertexData.vertices = vec3(i + offsetX, heightmap.y_vals[i][j], j + offsetZ);
                vertexData.normals = vec3(0.0f, 0.0f, 0.0f); //TODO: calculate normals
                vertexData.texCoords = vec2(i, j);
                vertexDataArray ~= vertexData;
            }
        }

        QuadList quadList = new QuadList(offsetX, offsetZ, n_patches, n_patches);

        m.mQuadList = quadList;
        m.mLODMethod = quadList;

        //setup state
        glGenVertexArrays(1, &m.mVAO);
        glBindVertexArray(m.mVAO);
        glGenBuffers(1, &m.mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, m.mVBO);
        glGenBuffers(1, &m.mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.mIBO);

        int POS_LOC = 0;
        int TEX_LOC = 1;

        glEnableVertexAttribArray(POS_LOC);
        glVertexAttribPointer(POS_LOC, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 5, cast(void*) 0);

        glEnableVertexAttribArray(TEX_LOC);
        glVertexAttribPointer(TEX_LOC, 2, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 5, cast(GLvoid*)(
                3 * GLfloat.sizeof));

        //end of setup state

        //populating buffers

        m.mQuadList.InitVertices(mVertexData, vertexDataArray);
        GLuint[] indices = [];
        m.mQuadList.InitIndices(indices);
        // writeln(mVertexData[0..50]);

        //vertex buffer
        glBufferData(GL_ARRAY_BUFFER, mVertexData.length * GLfloat.sizeof, mVertexData.ptr, GL_STATIC_DRAW);
        //index buffer
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STATIC_DRAW);
        //end of populating buffers

        glBindVertexArray(0);
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        // glDisableVertexAttribArray(2);
    }
    return m;
}

struct GraphicsApp
{
    bool mGameIsRunning = true;
    SDL_GLContext mContext;
    SDL_Window* mWindow;
    // Mesh mTerrainMesh;
    // Camera camera;

    Mesh mActiveMesh; // Assign to either triangle or bunny depending on key press
    Mesh[] mTerrainMeshes = [];
    auto mFillState = GL_FILL;

    GLuint mBasicGraphicsPipeline;
    float mHeightChange = 0;
    int mScreenWidth;
    int mScreenHeight;

    BasicCamera m_camera;

    /// Setup OpenGL and any libraries
    this(int width, int height)
    {
        mScreenWidth = width;
        mScreenHeight = height;

        // Setup SDL OpenGL Version
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        // We want to request a double buffer for smooth updating.
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

        // Create an application window using OpenGL that supports SDL
        mWindow = SDL_CreateWindow("dlang - OpenGL",
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            mScreenWidth,
            mScreenHeight,
            SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

        // Create the OpenGL context and associate it with our window
        mContext = SDL_GL_CreateContext(mWindow);

        // Load OpenGL Function calls
        auto retVal = LoadOpenGLLib();

        // Check OpenGL version
        GetOpenGLVersionInfo();

        InitCamera();
    }

    ~this()
    {
        // Destroy our context
        SDL_GL_DeleteContext(mContext);
        // Destroy our window
        SDL_DestroyWindow(mWindow);
    }

    /// Handle input
    void Input()
    {
        // Store an SDL Event
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            if (event.type == SDL_QUIT)
            {
                writeln("Exit event triggered (probably clicked 'x' at top of the window)");
                mGameIsRunning = false;
            }
            if (event.type == SDL_KEYDOWN)
            {
                if (event.key.keysym.scancode == SDL_SCANCODE_ESCAPE)
                {
                    writeln("Pressed escape key and now exiting...");
                    mGameIsRunning = false;
                }
                else if (event.key.keysym.scancode == SDL_SCANCODE_TAB)
                {
                    //Toggle wire mode
                    if (mFillState == GL_FILL)
                    {
                        mFillState = GL_LINE;
                    }
                    else
                    {
                        mFillState = GL_FILL;
                    }
                    writeln("Toggling Wire Mode");
                }
                m_camera.OnKeyboard(event.key.keysym.sym);

            }
            int mouseX, mouseY;
            SDL_GetMouseState(&mouseX, &mouseY);
            // m_camera.MouseLook(mouseX,mouseY);
            m_camera.OnMouse(mouseX, mouseY);
        }
        //TODO READD MOUSE LOOK

    }

    void InitCamera()
    {
        vec3 pos = vec3(0.0f, 50.0f, 0.0f);
        vec3 target = vec3(0.0f, 0.0f, 1.0f);
        vec3 up = vec3(0.0f, 1.0f, 0.0f);

        float FOV = 45.0f;
        float zNear = 0.1f;
        float zFar = 2000.0f;
        PersProjInfo persProjInfo = {
            FOV, cast(float) mScreenWidth, cast(float) mScreenHeight, zNear, zFar
        };

        m_camera = new BasicCamera(persProjInfo, pos, target, up);
        // m_camera = new BasicCamera(cast(float) mScreenWidth, cast(float) mScreenHeight);
    }

    void SetupScene()
    {
        // Build a basic shader
        // mBasicGraphicsPipeline = BuildBasicShader("./pipelines/basic/basic.vert", "./pipelines/basic/basic.frag");
        // // mat4 projectionMatrix = camera.getProjectionMatrix(45.0f, mScreenWidth / float(mScreenHeight), 0.1f, 100.0f);
        // GLuint vp = glGetUniformLocation(mBasicGraphicsPipeline, "view");
        // glUniformMatrix4fv(vp, 1, GL_TRUE, m_camera.GetViewProjMatrix().DataPtr());
        int num_chunks_width = 1;
        int num_chunks_height = 1;
        int base = 0;
        for (int i = 0; i < num_chunks_height; i++)
        {
            for (int j = 0; j < num_chunks_width; j++)
            {
                writeln("Generating terrain mesh at ", i, " ", j);
                // Generate a heightmap and create a mesh from it
                Mesh mTerrainMesh = MakeMeshFromHeightmap(generateHeightmap(513, 513, 2, i * 512 + base, j * 512 + base), i * 512 + base, j * 512 + base);

                mTerrainMeshes ~= mTerrainMesh;

            }
        }

        IMaterial material;
        if (mMode == "GEOMIP")
        {
            Pipeline texturePipeline = new Pipeline("multiTexturePipeline", "./pipelines/multitexture/basic.vert", "./pipelines/multitexture/basic.frag");

            // Pipeline texturePipeline = new Pipeline("multiTexturePipeline","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
            material = new MultiTextureMaterial("multiTexturePipeline", "./assets/grass.ppm", "./assets/sand.ppm", "./assets/dirt.ppm", "./assets/snow.ppm");
            material.AddUniform(new Uniform("gVP", "mat4", m_camera.GetViewProjMatrix()
                    .DataPtr()));
            material.AddUniform(new Uniform("sampler1", 0));
            material.AddUniform(new Uniform("sampler2", 1));
            material.AddUniform(new Uniform("sampler3", 2));
            material.AddUniform(new Uniform("sampler4", 3));
        }
        else if (mMode == "QUAD")
        {
            // import std.stdio;

            Pipeline texturePipeline = new Pipeline("multiTexturePipeline", "./pipelines/tesselator/basic.vert", "./pipelines/tesselator/basic.frag",
                "./pipelines/tesselator/basic.tesc", "./pipelines/tesselator/basic.tese");

            // Pipeline texturePipeline = new Pipeline("multiTexturePipeline","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
            material = new MutliTextureTesselated("multiTexturePipeline", "./assets/grass.ppm", "./assets/sand.ppm", "./assets/dirt.ppm", "./assets/snow.ppm", "./assets/heightmap.ppm");
            material.AddUniform(new Uniform("gVP", "mat4", m_camera.GetViewProjMatrix()
                    .DataPtr()));
            material.AddUniform(new Uniform("gView", "mat4", m_camera.GetMatrix()
                    .DataPtr()));
            material.AddUniform(new Uniform("sampler1", 0));
            material.AddUniform(new Uniform("sampler2", 1));
            material.AddUniform(new Uniform("sampler3", 2));
            material.AddUniform(new Uniform("sampler4", 3));
            material.AddUniform(new Uniform("gHeightMap", 4));
        }

        foreach (ref mesh; mTerrainMeshes)
        {
            mesh.mMaterial = material;
        }

    }

    /// Update gamestate
    void Update()
    {
    }

    void Render()
    {
        // Clear the renderer each time we render
        glViewport(0, 0, mScreenWidth, mScreenHeight);
        // Clear the renderer each time we render
        glClearColor(0.0f, 0.0f, 255.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_DEPTH);
        glEnable(GL_DEPTH_TEST);
        // glEnable(GL_CULL_FACE);

        // Do opengl drawing
        // glUseProgram(mBasicGraphicsPipeline);

        //faster to do viewProj mult on cpu instead of n times on GPU for each vertex
        // GLuint viewProj = glGetUniformLocation(mBasicGraphicsPipeline, "gVP");
        // multiTextureMaterial.update(); //TODO FIX THISm dont need a scene tree, but need to correctly update texture maps etc, think we can just do this one time

        // Send matrices to shader
        // TRANSPOSING WAS THE MAIN ISSUE
        // glUniformMatrix4fv(viewProj, 1, GL_TRUE, m_camera.GetViewProjMatrix().DataPtr());

        PipelineUse("multiTexturePipeline");

        foreach (mesh; mTerrainMeshes)
        {
            mActiveMesh = mesh;
            //mesh updating
            mActiveMesh.mMaterial.Update();
            mActiveMesh.mMaterial.mUniformMap["gVP"].Set(m_camera.GetViewProjMatrix().DataPtr());
            if (mMode == "QUAD")
            {
                mActiveMesh.mMaterial.mUniformMap["gView"].Set(m_camera.GetMatrix().DataPtr());
            }
            foreach (u; mActiveMesh.mMaterial.mUniformMap)
            {
                u.Transfer();
            }

            //on LOD change, the following will also change internally, ibo and mNumindices --not actually changing anything about the VBO
            glBindVertexArray(mActiveMesh.mVAO);
            glBindBuffer(GL_ARRAY_BUFFER, mActiveMesh.mVBO);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mActiveMesh.mIBO);

            glPolygonMode(GL_FRONT_AND_BACK, mFillState); //https://docs.gl/gl4/glPolygonMode

            // glDrawElements(GL_TRIANGLES, mActiveMesh.mNumIndices, GL_UNSIGNED_INT, null);

            mActiveMesh.mLODMethod.Render(m_camera.m_pos); // TODO should make a call to geomip
            // glBindVertexArray(0);
        }

        SDL_GL_SwapWindow(mWindow);
    }

    /// Process 1 frame
    void AdvanceFrame()
    {
        
        Input();
        Update();
        Render();
    }

    /// Main application loop
    void Loop()
    {
        // Setup the graphics scene
        SetupScene();
        // Run the graphics application loop
        SDL_WarpMouseInWindow(mWindow, mScreenWidth / 2, mScreenHeight / 2);

        uint lastTime =  SDL_GetTicks();
        int nbFrames = 0;

 
       
        
        while (mGameIsRunning)
        {
            AdvanceFrame();
            uint currentTime = SDL_GetTicks();
            nbFrames++;
            if ( currentTime - lastTime >= 1000 ){ // If last prinf() was more than 1 sec ago
                // printf and reset timer
                printf("%f ms/frame\n", 1000/double(nbFrames));
                // printf("%f frame/s\n", double(nbFrames));
                nbFrames = 0;
                lastTime += 1000;
            }
        }
    }
}

string mMode = "QUAD"; // "GEOMIP" or "QUAD"

/*
//initializing for basic mesh
    my very bad sketch of a quad
            
   #4          #3
    ___________
    |        /| 
    |    /    |
    | /       |
    ___________
   #1         #2 

    Ordering for this would be 1,2,3 and 1,3,4

    adding verts in this order
    #m+1      #2m
    ___________
    |        /| 
    |    /    |
    | /       |
    ___________
   #0         #m 

   */
