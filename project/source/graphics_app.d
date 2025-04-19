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
}

//Function to create our quadmap from our heightmap generator
Mesh MakeMeshFromHeightmap(HeightMap heightmap)
{
    Mesh m;

    // Initialize VBO and IBO

    //example data:[0,0,0 // the vertex data
    //              1,1,1 // the color data
    //]
    GLfloat[] mVertexData = [];
    for (int i = 0; i < heightmap.width; i++)
    {
        for (int j = 0; j < heightmap.height; j++)
        {
            //Vertex data TODO CHECK IF X,Y,Z is correct 
            // mVertexData ~= (i - heightmap.width / 2) * 1;
            mVertexData ~= i;
            mVertexData ~= heightmap.y_vals[i][j];
            // mVertexData ~= 10;
            // mVertexData ~= (j - heightmap.height / 2) * 1;
            mVertexData ~= j;
            //Normal data
            //random number between 0 and 1

            import std.random;

        
            mVertexData ~= (heightmap.y_vals[i][j] + 5) / 15;
            mVertexData ~= (heightmap.y_vals[i][j] + 5) / 15;
            mVertexData ~= (heightmap.y_vals[i][j] + 5) / 15;
            mVertexData ~= i/m_width;
            mVertexData ~= j/m_height;
            
        }
    }

    //debug func
    // for(int i = 0; i < mVertexData.length; i += 6){
    //     write(mVertexData[i], " ");
    //     write(mVertexData[i+1], " ");
    //     write(mVertexData[i+2], " ");
    //     writeln();
    // }

    //Index Data:
    //Example 
    /*
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

    //initializing for basic mesh
    // GLuint[] mIndices = InitIndices(heightmap.width, heightmap.height);
    //m.mNumIndices = cast(int) mIndices.length;

    //initializion for fan mesh

    int patch_size = 3;
    GLuint[] mIndices = GeomipInitIndices(heightmap.width, heightmap.height, patch_size);

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
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 5, cast(void*) 0);

    // // normals
    // glEnableVertexAttribArray(1);
    // glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 6, cast(GLvoid*)(
    //         GLfloat.sizeof * 3));
    //Textures instead
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, GLfloat.sizeof * 5, cast(GLvoid*)(
            GLfloat.sizeof * 3));


    // Unbind our currently bound Vertex Array Object
    glBindVertexArray(0);
    // Disable any attributes we opened in our Vertex Attribute Arrray,
    // as we do not want to leave them open. 
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    return m;
}

struct GraphicsApp
{
    bool mGameIsRunning = true;
    SDL_GLContext mContext;
    SDL_Window* mWindow;
    Mesh mTerrainMesh;
    // Camera camera;

    Mesh mActiveMesh; // Assign to either triangle or bunny depending on key press
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
                // else if(event.key.keysym.sym == SDLK_DOWN){
                //     m_camera.MoveBackward();
                // }
                // else if(event.key.keysym.sym == SDLK_UP){
                //     m_camera.MoveForward();
                // }
                // else if(event.key.keysym.sym == SDLK_LEFT){
                //     m_camera.MoveLeft();
                // }
                // else if(event.key.keysym.sym == SDLK_RIGHT){
                //     m_camera.MoveRight();
                // }
                // else if(event.key.keysym.sym == SDLK_LSHIFT){
                //     m_camera.MoveUp();
                // }
                // else if(event.key.keysym.sym == SDLK_LCTRL){
                //     m_camera.MoveDown();
                // }
                // writeln("Camera Position: ",camera.mEyePosition);
                // m_camera.debugCamera();

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
        float zFar = 1000.0f;
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

        mTerrainMesh = MakeMeshFromHeightmap(generateHeightmap(513, 513, 2));
        
        Pipeline texturePipeline = new Pipeline("multiTexturePipeline","./pipelines/multitexture/basic.vert","./pipelines/multitexture/basic.frag");
        // Pipeline texturePipeline = new Pipeline("multiTexturePipeline","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
        IMaterial multiTextureMaterial = new MultiTextureMaterial("multiTexturePipeline","./assets/sand.ppm","./assets/grass.ppm","./assets/dirt.ppm","./assets/snow.ppm");
        multiTextureMaterial.AddUniform(new Uniform("gVP", "mat4", m_camera.GetViewProjMatrix().DataPtr()));
        multiTextureMaterial.AddUniform(new Uniform("sampler1", 0));
        multiTextureMaterial.AddUniform(new Uniform("sampler2", 1));
        multiTextureMaterial.AddUniform(new Uniform("sampler3", 2));
        multiTextureMaterial.AddUniform(new Uniform("sampler4", 3));
        // multiTextureMaterial.Update();
        mTerrainMesh.mMaterial = multiTextureMaterial;

        mActiveMesh = mTerrainMesh;
        // MeshNode  m2   = new MeshNode("terrain",terrain,multiTextureMaterial);
		// mSceneTree.GetRootNode().AddChildSceneNode(m2);
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


        //mesh updating
        mActiveMesh.mMaterial.Update();
        mActiveMesh.mMaterial.mUniformMap["gVP"].Set(m_camera.GetViewProjMatrix().DataPtr());
        foreach(u ; mActiveMesh.mMaterial.mUniformMap)
        {
            u.Transfer();
        }

        //on LOD change, the following will also change internally, ibo and mNumindices --not actually changing anything about the VBO
        glBindVertexArray(mActiveMesh.mVAO);
        glBindBuffer(GL_ARRAY_BUFFER, mActiveMesh.mVBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mActiveMesh.mIBO);

        glPolygonMode(GL_FRONT_AND_BACK, mFillState); //https://docs.gl/gl4/glPolygonMode

        // glDrawElements(GL_TRIANGLES, mActiveMesh.mNumIndices, GL_UNSIGNED_INT, null);
        RenderGeo(m_camera.m_pos); // TODO should make a call to geomip
        // glBindVertexArray(0);

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

        while (mGameIsRunning)
        {
            AdvanceFrame();
        }
    }
}
