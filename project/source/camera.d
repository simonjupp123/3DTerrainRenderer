// module camera;

// import linear;

// class Camera {
//     vec3 position;
//     vec3 front;
//     vec3 up;
//     float yaw;
//     float pitch;
//     float speed;
//     float sensitivity;

//     this(vec3 pos, vec3 frontDir, vec3 upDir) {
//         position = pos;
//         front = frontDir;
//         up = upDir;
//         yaw = -90.0;
//         pitch = 0.0;
//         speed = 0.05;
//         sensitivity = 0.1;
//     }

//     mat4 getViewMatrix() {
//         vec3 center = position + front;
//         return lookAt(position, center, up);
//     }

//     mat4 lookAt(vec3 eye, vec3 target, vec3 up) {
//         vec3 f = Normalize(target - eye);
//         vec3 s = Normalize(Cross(f, up));
//         vec3 u = Cross(s, f);

//         return mat4([
//             s.x,  u.x, -f.x,  0.0,
//             s.y,  u.y, -f.y,  0.0,
//             s.z,  u.z, -f.z,  0.0,
//             -Dot(s, eye), -Dot(u, eye), Dot(f, eye), 1.0
//         ]);
//     }   
// }
/// This represents a camera abstraction.
module camera;

import linear;
import bindbc.opengl;
import std.math;
import std.stdio;

/// Camera abstraction.
// class Camera{
//     mat4 mViewMatrix;
//     mat4 mProjectionMatrix;

//     vec3 mEyePosition;          /// This is our 'translation' value
//     // Axis of the camera
//     vec3 mUpVector;             /// This is 'up' in the world
//     vec3 mForwardVector;        /// This is on the camera axis
//     vec3 mRightVector;          /// This is where 'right' is
//     bool firstMouse = true;
//     float yaw = -90.0f;       
//     float pitch = 0.0f;      
//     float lastX = 400, lastY = 300;
//     /// Constructor for a camera
//     this(){
//         // Setup our camera (view matrix) 
//         mViewMatrix = MatrixMakeIdentity();

//         // Setup our perspective projection matrix
//         // NOTE: Assumption made here is our window is always 640/480 or the similar aspect ratio.
//         mProjectionMatrix = MatrixMakePerspective(90.0f.ToRadians, 480.0f/640.0f, 0.1f, 1000.0f);

//         /// Initial Camera setup
//         mEyePosition    = vec3(2.0f, 2.0f, 2.0f);
//         // Eye position
//         // Forward vector matching the positive z-axis
//         mForwardVector  = vec3(0.0f, 0.0f, -1.0f);
//         // Where up is in the world initially
//         mUpVector       = vec3(0.0f,1.0f,0.0f);
//         // Where right is initially
//         mRightVector    = vec3(1.0f, 0.0f, 0.0f);

//         // Camera Position: <1,0,0>
//         // Camera Position: <1,0,0>
//         // Camera Forward: <0,0,1>
//         // Camera Right: <1,0,0>
//         // // Camera Up: <0,1,0>
//         // Camera Position: <1,0,2>
//         // Camera Position: <1,0,2>
//         // Camera Forward: <0,0,1>
//         // Camera Right: <1,0,0>
//         // Camera Up: <0,1,0>

//     }

//     /// Position the eye of the camera in the world
//     void SetCameraPosition(vec3 v){

//         mEyePosition = v;
//         UpdateViewMatrix();

//     }
//     /// Position the eye of the camera in the world
//     void SetCameraPosition(float x, float y, float z){
//         UpdateViewMatrix();
//         mEyePosition = vec3(x,y,z);

//     }

//     mat4 LookAt(vec3 eye, vec3 direction, vec3 up){

//         mat4 translation = MatrixMakeTranslation(-mEyePosition);

//         mat4 look = mat4(mRightVector.x,    mRightVector.y,     mRightVector.z  , 0.0f,
//                          mUpVector.x,       mUpVector.y,        mUpVector.z     , 0.0f,
//                          mForwardVector.x,  mForwardVector.y,   mForwardVector.z, 0.0f,
//                          0.0f, 0.0f, 0.0f, 1.0f);

// 				look = look.MatrixTranspose(); //pretty sure you dont want to transpose this but not sure

//         return (look * translation); 
//     }

//     /// Sets the view matrix and also retrieves it
//     /// Retrieves the camera view matrix
//     mat4 UpdateViewMatrix(){
//         mViewMatrix = LookAt(mEyePosition,
//                              mForwardVector,
//                              mUpVector);
//         return mViewMatrix;
//     }

//     /// Mouse look function
//     void MouseLook(int mouseX, int mouseY){

//         UpdateViewMatrix();
//         static bool firstMouse = true;
//         static lastX = 0;
//         static lastY = 0;
//         if(firstMouse){
//             firstMouse = false;
//             lastX = mouseX;
//             lastY = mouseY;
//         }

//         float deltaX = (mouseX-lastX)*.01;
//         float deltaY = (mouseY-lastY)*.01;

//         mForwardVector = mForwardVector.Normalize();
//         mForwardVector = mat3(MatrixMakeYRotation(deltaX)) * mForwardVector;
// 		mForwardVector = mForwardVector.Normalize();

// 		mRightVector = Cross(mForwardVector,mUpVector);
// 		mRightVector = mRightVector.Normalize();

//         lastX = mouseX;
//         lastY = mouseY;

//     }

//     void MoveForward(){
//         // UpdateViewMatrix();
//         // TODO 
// 		vec3 direction = mForwardVector;
// 		direction = direction * 1.0f;		

//         SetCameraPosition(mEyePosition.x - direction.x, 
// 														mEyePosition.y - direction.y,
// 														mEyePosition.z - direction.z);
//     }

//     void MoveBackward(){
//         // UpdateViewMatrix();
//         // TODO 
// 		vec3 direction = mForwardVector;
// 		direction = direction * 1.0f;		

//         SetCameraPosition(mEyePosition.x + direction.x, 
// 												  mEyePosition.y + direction.y,
// 												  mEyePosition.z + direction.z);
//     }

//     void MoveLeft(){
//         UpdateViewMatrix();
//         // TODO 

//         SetCameraPosition(mEyePosition.x - mRightVector.x, 
// 										      mEyePosition.y - mRightVector.y,
// 												  mEyePosition.z - mRightVector.z);

//     }

//     void MoveRight(){
//         UpdateViewMatrix();
//         // TODO 
//         SetCameraPosition(mEyePosition.x + mRightVector.x, 
// 					      					mEyePosition.y + mRightVector.y,
// 						  						mEyePosition.z + mRightVector.z);
//     }

//     void MoveUp(){
//         UpdateViewMatrix();
//         // TODO 
//         SetCameraPosition(mEyePosition.x, 
// 					     						 mEyePosition.y + 0.1f,
// 						  						 mEyePosition.z);
//     }

//     void MoveDown(){
//         UpdateViewMatrix();
//         // TODO 
//         SetCameraPosition(mEyePosition.x, 
// 					     						 mEyePosition.y - 0.1f,
// 						  						 mEyePosition.z);
//     }

/// This represents a camera abstraction.

/// Camera abstraction.
class Camera
{
    mat4 mViewMatrix;
    mat4 mProjectionMatrix;

    vec3 mEyePosition; /// This is our 'translation' value
    // Axis of the camera
    vec3 mUpVector; /// This is 'up' in the world
    vec3 mForwardVector; /// This is on the camera axis
    vec3 mRightVector; /// This is where 'right' is
    bool firstMouse = true;
    float yaw = -90.0f;
    float pitch = 0.0f;
    float lastX = 400, lastY = 300;
    /// Constructor for a camera
    this()
    {
        // Setup our camera (view matrix) 
        mViewMatrix = MatrixMakeIdentity();

        // Setup our perspective projection matrix
        // NOTE: Assumption made here is our window is always 640/480 or the similar aspect ratio.
        mProjectionMatrix = MatrixMakePerspective(90.0f.ToRadians, 480.0f / 640.0f, 0.1f, 100.0f);

        /// Initial Camera setup
        mEyePosition = vec3(0.0f, 0.0f, 1.0f);
        // Eye position
        // Forward vector matching the positive z-axis
        mForwardVector = vec3(0.0f, 0.0f, 1.0f);
        // Where up is in the world initially
        mUpVector = vec3(0.0f, 1.0f, 0.0f);
        // Where right is initially
        mRightVector = vec3(1.0f, 0.0f, 0.0f);

    }

    /// Position the eye of the camera in the world
    void SetCameraPosition(vec3 v)
    {
        UpdateViewMatrix();
        mEyePosition = v;
    }
    /// Position the eye of the camera in the world
    void SetCameraPosition(float x, float y, float z)
    {
        UpdateViewMatrix();
        mEyePosition = vec3(x, y, z);
    }

    /// Builds a matrix for where the matrix is looking
    /// given the following parameters
    mat4 LookAt(vec3 eye, vec3 direction, vec3 up)
    {
        // TODO
        //calc right vec using cross prod of up and dir:
        direction = Normalize(direction);
        up = Normalize(up);
        vec3 right = Normalize(Cross(up, direction));

        // mUpVector = Normalize(Cross(direction, mRightVector));
        mat4 lookAt = MatrixMakeIdentity();
        lookAt[0] = vec4(right.x, right.y, right.z, 0.0f);
        lookAt[1] = vec4(up.x, up.y, up.z, 0.0f);
        lookAt[2] = vec4(direction.x, direction.y, direction.z, 0.0f);
        lookAt = MatrixTranspose(lookAt);

        mat4 pos = MatrixMakeIdentity();
        pos[3] = vec4(-eye.x, -eye.y, -eye.z, 1.0f);
        // Note: I would recommend handling this in 2 parts
        //       1. First try handling translation (Remember camera moves opposite of world)
        //       2. Then add the 'look' vector that handles rotation.
        // 
        // Consider which matrix you need to transpose in order to 'invert'
        // the operation.
        mat4 result;
        result = lookAt * pos;

        return result;
    }

    /// Sets the view matrix and also retrieves it
    /// Retrieves the camera view matrix
    mat4 UpdateViewMatrix()
    {
        mViewMatrix = LookAt(mEyePosition,
            mForwardVector,
            mUpVector);
        return mViewMatrix;
    }

    /// Mouse look function
    void MouseLook(int mouseX, int mouseY)
    {
        // https://learnopengl.com/Getting-started/Camera
        if (firstMouse)
        {
            lastX = mouseX;
            lastY = mouseY;
            firstMouse = false;
        }
        float xoffset = mouseX - lastX;
        float yoffset = lastY - mouseY;
        lastX = mouseX;
        lastY = mouseY;

        const float sensitivity = 4.35f;
        xoffset *= sensitivity;
        yoffset *= sensitivity;

        yaw += xoffset;
        pitch += yoffset;

        if (pitch > 89.0f)
            pitch = 89.0f;
        if (pitch < -89.0f)
            pitch = -89.0f;

        vec3 dir;
        dir.x = cos(yaw.ToRadians) * cos(pitch.ToRadians);
        dir.y = sin(pitch.ToRadians);
        dir.z = sin(yaw.ToRadians) * cos(pitch.ToRadians);

        mForwardVector = dir;

        mRightVector = Normalize(Cross(mForwardVector, mUpVector));

        UpdateViewMatrix();
        // TODO 

    }

    void MoveForward()
    {
        vec3 change = mForwardVector * 1.0f;
        mEyePosition = mEyePosition - change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveBackward()
    {
        vec3 change = mForwardVector * 1.0f;
        mEyePosition = mEyePosition + change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveLeft()
    {
        vec3 change = mRightVector * 1.0f;
        mEyePosition = mEyePosition + change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveRight()
    {
        vec3 change = mRightVector * 1.0f;
        mEyePosition = mEyePosition - change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveUp()
    {
        UpdateViewMatrix();
        // TODO 
        SetCameraPosition(mEyePosition.x,
            mEyePosition.y + 0.1f,
            mEyePosition.z);
    }

    void MoveDown()
    {
        UpdateViewMatrix();
        // TODO 
        SetCameraPosition(mEyePosition.x,
            mEyePosition.y - 0.1f,
            mEyePosition.z);
    }

    mat4 getViewMatrix()
    {
        return mViewMatrix;
    }

    mat4 getProjectionMatrix()
    {
        return mProjectionMatrix;
    }

    void debugCamera()
    {
        writeln("Camera Position: ", mEyePosition);
        writeln("Camera Forward: ", mForwardVector);
        writeln("Camera Right: ", mRightVector);
        writeln("Camera Up: ", mUpVector);
    }
}
