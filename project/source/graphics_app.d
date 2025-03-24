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
import camera;
import linear;



/// Create a basic shader
/// The result is a 'GLuint' representing the compiled 'program object' or otherwise 'graphics pipeline'
/// that is compiled and ready to execute on the GPU.
GLuint BuildBasicShader(string vertexShaderSourceFilename, string fragmentShaderSourceFilename){

    // Local nested function -- not meant for otherwise calling freely
    void CheckShaderError(GLuint shaderObject){
        // Retrieve the result of our compilation
        int result;
        // Our goal with glGetShaderiv is to retrieve the compilation status
        glGetShaderiv(shaderObject, GL_COMPILE_STATUS, &result);

       
        if(result == GL_FALSE){
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
    string vertexSource 	= readText(vertexShaderSourceFilename);
    string fragmentSource 	= readText(fragmentShaderSourceFilename);

    // Compile vertex shader
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char* vertSource = vertexSource.ptr;
    glShaderSource(vertexShader, 1, &vertSource, null);
    glCompileShader(vertexShader);
    CheckShaderError(vertexShader);

    // Compile fragment shader
    fragmentShader= glCreateShader(GL_FRAGMENT_SHADER);
    const char* fragSource = fragmentSource.ptr;
    glShaderSource(fragmentShader, 1, &fragSource, null);
    glCompileShader(fragmentShader);
    CheckShaderError(fragmentShader);

    // Create shader pipeline
    programObjectID = glCreateProgram();

    // Link our two shader programs together.
    // Consider this the equivalent of taking two .cpp files, and linking them into
    // one executable file.
    glAttachShader(programObjectID,vertexShader);
    glAttachShader(programObjectID,fragmentShader);
    glLinkProgram(programObjectID);

    // Validate our program
    glValidateProgram(programObjectID);

    // Once our final program Object has been created, we can
    // detach and then delete our individual shaders.
    glDetachShader(programObjectID,vertexShader);
    glDetachShader(programObjectID,fragmentShader);
    // Delete the individual shaders once we are done
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    PrintProgram(programObjectID);
    return programObjectID;
}

void PrintProgram(GLuint programID){
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
        printf("#%i name: %.*s\n", i,length, uniform_name.ptr);
    }
}


struct Mesh{
    GLuint mVAO;
    GLuint mVBO;
    GLuint mIBO; 
    int mNumIndices;
}

//Function to create our quadmap from our heightmap generator
Mesh MakeMeshFromHeightmap(HeightMap heightmap){
    Mesh m;

    // Initialize VBO and IBO

    //example data:[0,0,0 // the vertex data
    //              1,1,1 // the color data
    //]
    GLfloat[] mVertexData= [];
    for(int i = 0; i < heightmap.width; i++){
        for(int j = 0; j < heightmap.height; j++){
            //Vertex data
            mVertexData ~= (i - heightmap.width/2) * 1;
            mVertexData ~= heightmap.y_vals[i][j];
            mVertexData ~= (j - heightmap.height/2) * 1;
            
            
            //Normal data
            //random number between 0 and 1

            import std.random;

            // mVertexData ~= heightmap.y_vals[i][j];
            // mVertexData ~= heightmap.y_vals[i][j];
            // mVertexData ~= heightmap.y_vals[i][j];
            mVertexData ~= uniform(0.0,1.0);
            mVertexData ~= uniform(0.0,1.0);
            mVertexData ~= uniform(0.0,1.0);
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
    GLuint[] mIndices = InitIndices(heightmap.width, heightmap.height);
    m.mNumIndices = cast(int) mIndices.length;

     // Vertex Arrays Object (VAO) Setup
    glGenVertexArrays(1, &m.mVAO);
    glBindVertexArray(m.mVAO);

    // Vertex Buffer Object (VBO) creation
    glGenBuffers(1, &m.mVBO);
    glBindBuffer(GL_ARRAY_BUFFER, m.mVBO);
    glBufferData(GL_ARRAY_BUFFER, mVertexData.length* GLfloat.sizeof, mVertexData.ptr, GL_STATIC_DRAW);

    //Index Buffer to increase efficiency
    glGenBuffers(1, &m.mIBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.mIBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, mIndices.length * GLuint.sizeof, mIndices.ptr, GL_STATIC_DRAW);
   
    //positions
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof*6, cast(void*)0);

    // normals
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, GLfloat.sizeof*6, cast(GLvoid*)(GLfloat.sizeof*3));

    

    // Unbind our currently bound Vertex Array Object
    glBindVertexArray(0);
    // Disable any attributes we opened in our Vertex Attribute Arrray,
    // as we do not want to leave them open. 
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    return m;
}

GLuint[] InitIndices(int width, int height){
    GLuint[] indices;
    for(int i = 0; i < width-1; i++){
        for(int j = 0; j < height-1; j++){
            //Triangle 1
            indices ~= i*height + j; //bottom left
            indices ~= i*height + j+1; //bottom right
            indices ~= (i+1)*height + j+1; //top right
            //Triangle 2
            indices ~= i*height + j;//bottom left
            indices ~= (i+1)*height + j+1;//top right
            indices ~= (i+1)*height + j;//top left
        }
    }
    return indices;
}




struct GraphicsApp{
    bool mGameIsRunning=true;
    SDL_GLContext mContext;
    SDL_Window* mWindow;
    Mesh mTerrainMesh;
    Camera camera;
    
    Mesh mActiveMesh; // Assign to either triangle or bunny depending on key press
    auto mFillState = GL_FILL;

    GLuint mBasicGraphicsPipeline;
    float mHeightChange = 0;
    int mScreenWidth = 640;
    int mScreenHeight = 480;

    /// Setup OpenGL and any libraries
    this(int width, int height){
        mScreenWidth = width;
        mScreenHeight = height;

        // Setup SDL OpenGL Version
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 4 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 1 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
        // We want to request a double buffer for smooth updating.
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

        // Create an application window using OpenGL that supports SDL
        mWindow = SDL_CreateWindow( "dlang - OpenGL",
                SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED,
                mScreenWidth,
                mScreenHeight,
                SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN );

        // Create the OpenGL context and associate it with our window
        mContext = SDL_GL_CreateContext(mWindow);

        // Load OpenGL Function calls
        auto retVal = LoadOpenGLLib();

        // Check OpenGL version
        GetOpenGLVersionInfo();

        camera = new Camera();
    }

    ~this(){
        // Destroy our context
        SDL_GL_DeleteContext(mContext);
        // Destroy our window
        SDL_DestroyWindow(mWindow);
    }

    /// Handle input
    void Input(){
        // Store an SDL Event
        SDL_Event event;
        while(SDL_PollEvent(&event)){
            if(event.type == SDL_QUIT){
                writeln("Exit event triggered (probably clicked 'x' at top of the window)");
                mGameIsRunning= false;
            }
            if(event.type == SDL_KEYDOWN){
                if(event.key.keysym.scancode == SDL_SCANCODE_ESCAPE){
                    writeln("Pressed escape key and now exiting...");
                    mGameIsRunning= false;
                }
                else if(event.key.keysym.scancode == SDL_SCANCODE_W){
                    //Toggle wire mode
                    if(mFillState == GL_FILL){
                        mFillState = GL_LINE;
                    }
                    else{
                        mFillState = GL_FILL;
                    }
                    writeln("Toggling Wire Mode");
                }
                else if(event.key.keysym.sym == SDLK_DOWN){
                    camera.MoveBackward();
                }
                else if(event.key.keysym.sym == SDLK_UP){
                    camera.MoveForward();
                }
                else if(event.key.keysym.sym == SDLK_LEFT){
                    camera.MoveLeft();
                }
                else if(event.key.keysym.sym == SDLK_RIGHT){
                    camera.MoveRight();
                }
                else if(event.key.keysym.sym == SDLK_LSHIFT){
                    camera.MoveUp();
                }
                else if(event.key.keysym.sym == SDLK_LCTRL){
                    camera.MoveDown();
                }
                writeln("Camera Position: ",camera.mEyePosition);
                camera.debugCamera();
            
						
            }
        }
        int mouseX,mouseY;
        SDL_GetMouseState(&mouseX,&mouseY);
        camera.MouseLook(mouseX,mouseY);
    }

    void SetupScene(){
        // Build a basic shader
        mBasicGraphicsPipeline = BuildBasicShader("./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
        // mat4 projectionMatrix = camera.getProjectionMatrix(45.0f, mScreenWidth / float(mScreenHeight), 0.1f, 100.0f);
        // GLuint viewLoc = glGetUniformLocation(mBasicGraphicsPipeline, "view");
        // GLuint projLoc = glGetUniformLocation(mBasicGraphicsPipeline, "projection");

        // glUniformMatrix4fv(viewLoc, 1, GL_FALSE, camera.getViewMatrix().DataPtr());
        // glUniformMatrix4fv(projLoc, 1, GL_FALSE, projectionMatrix.DataPtr());

        
        mTerrainMesh = MakeMeshFromHeightmap(generateHeightmap(256,256,5));
        mActiveMesh = mTerrainMesh;
    }

    /// Update gamestate
    void Update(){
    }

    void Render(){
        // Clear the renderer each time we render
         glViewport(0,0,mScreenWidth, mScreenHeight);
        // Clear the renderer each time we render
        glClearColor(0.0f,0.6f,0.8f,1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        // glEnable(GL_DEPTH);
        glEnable(GL_DEPTH_TEST); 
        glEnable(GL_CULL_FACE);


        // Do opengl drawing
        glUseProgram(mBasicGraphicsPipeline);

        GLuint viewLoc = glGetUniformLocation(mBasicGraphicsPipeline, "uView");
        GLuint projLoc = glGetUniformLocation(mBasicGraphicsPipeline, "uProjection");

        // Get matrices from Camera
        mat4 viewMatrix = camera.getViewMatrix();
        mat4 projectionMatrix = camera.getProjectionMatrix(90.0f, 640.0f / 480.0f, 0.1f, 100.0f);

        // Send matrices to shader
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, viewMatrix.DataPtr());
        glUniformMatrix4fv(projLoc, 1, GL_FALSE, projectionMatrix.DataPtr());

        glBindVertexArray(mActiveMesh.mVAO);
        glBindBuffer(GL_ARRAY_BUFFER, mActiveMesh.mVBO); 
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mActiveMesh.mIBO);

        glPolygonMode(GL_FRONT_AND_BACK, mFillState); //https://docs.gl/gl4/glPolygonMode
        
        glDrawElements(GL_TRIANGLES, mActiveMesh.mNumIndices, GL_UNSIGNED_INT, null);
        // glBindVertexArray(0);



        SDL_GL_SwapWindow(mWindow);
    }

    //from https://github.com/emeiri/ogldev/blob/master/Terrain1/terrain_demo1.cpp
    // void InitCamera()
    // {
    //     Vector3f pos = Vector3f(100.0f, 220.0f, -400.0f);
    //     Vector3f target = Vector3f(0.0f, -0.25f, 1.0f);
    //     Vector3f up = Vector3f(0.0, 1.0f, 0.0f);

    //     float FOV = 45.0f;
    //     float zNear = 0.1f;
    //     float zFar = 2000.0f;
    //     PersProjInfo persProjInfo = { FOV, cast(float) WINDOW_WIDTH, cast(float) WINDOW_HEIGHT, zNear, zFar };

    //     m_pGameCamera = new BasicCamera(persProjInfo, pos, target, up);
    // }

    /// Process 1 frame
    void AdvanceFrame(){
        Input();
        Update();
        Render();
    }

    /// Main application loop
    void Loop(){
        // Setup the graphics scene
        SetupScene();
        // Run the graphics application loop
        SDL_WarpMouseInWindow(mWindow,640/2,320/2);

        while(mGameIsRunning){
            AdvanceFrame();
        }
    }
}
