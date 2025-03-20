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
class Camera{
    mat4 mViewMatrix;
    mat4 mProjectionMatrix;

    vec3 mEyePosition;          /// This is our 'translation' value
    // Axis of the camera
    vec3 mUpVector;             /// This is 'up' in the world
    vec3 mForwardVector;        /// This is on the camera axis
    vec3 mRightVector;          /// This is where 'right' is
    bool firstMouse = true;
    float yaw = -90.0f;       
    float pitch = 0.0f;      
    float lastX = 400, lastY = 300;
    /// Constructor for a camera
    this(){
        // Setup our camera (view matrix) 
        mViewMatrix = MatrixMakeIdentity();

        // Setup our perspective projection matrix
        // NOTE: Assumption made here is our window is always 640/480 or the similar aspect ratio.
        mProjectionMatrix = MatrixMakePerspective(90.0f.ToRadians,480.0f/640.0f, 0.1f, 100.0f);

        /// Initial Camera setup
        mEyePosition    = vec3(0.0f, 10.0f, 0.0f);
        // Eye position
        // Forward vector matching the positive z-axis
        mForwardVector  = vec3(0.0f, -10.0f, 0.0f);
        // Where up is in the world initially
        mUpVector       = vec3(1.0f,1.0f,0.0f);
        // Where right is initially
        mRightVector    = vec3(0.0f, 0.0f, 1.0f);

    }

    /// Position the eye of the camera in the world
    void SetCameraPosition(vec3 v){
        UpdateViewMatrix();
        mEyePosition = v;
    }
    /// Position the eye of the camera in the world
    void SetCameraPosition(float x, float y, float z){
        UpdateViewMatrix();
        mEyePosition = vec3(x,y,z);
    }

    /// Builds a matrix for where the matrix is looking
    /// given the following parameters
    mat4 LookAt(vec3 eye, vec3 direction, vec3 up){
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
    mat4 UpdateViewMatrix(){
        mViewMatrix = LookAt(mEyePosition,
                             mForwardVector,
                             mUpVector);
        return mViewMatrix;
    }

    /// Mouse look function
    void MouseLook(int mouseX, int mouseY){
        // https://learnopengl.com/Getting-started/Camera
        // if (firstMouse)
        // {
        //     lastX = mouseX;
        //     lastY = mouseY;
        //     firstMouse = false;
        // }
        // float xoffset = mouseX - lastX;
        // float yoffset = lastY - mouseY; 
        // lastX = mouseX;
        // lastY = mouseY;

        // const float sensitivity = 0.35f;
        // xoffset *= sensitivity;
        // yoffset *= sensitivity;

        // yaw   += xoffset;
        // pitch += yoffset; 

        // if(pitch > 89.0f)
        //     pitch =  89.0f;
        // if(pitch < -89.0f)
        //     pitch = -89.0f;

        // vec3 dir;
        // dir.x = cos(yaw.ToRadians) * cos(pitch.ToRadians);
        // dir.y = sin(pitch.ToRadians);
        // dir.z = sin(yaw.ToRadians) * cos(pitch.ToRadians);
        
        // mForwardVector = dir;

        // mRightVector = Normalize(Cross(mForwardVector, mUpVector));

        // UpdateViewMatrix();
        // TODO 

    }

    void MoveForward(){
        vec3 change = mForwardVector * 1.0f;
        mEyePosition = mEyePosition - change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveBackward(){
        vec3 change = mForwardVector * 1.0f;
        mEyePosition = mEyePosition + change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveLeft(){
        vec3 change = mRightVector * 1.0f;
        mEyePosition = mEyePosition + change;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveRight(){
        vec3 change = mRightVector * 1.0f;
        mEyePosition = mEyePosition - change;
        UpdateViewMatrix();
        // TODO 
    }

    mat4 getViewMatrix(){
        return mViewMatrix;
    }

    mat4 getProjectionMatrix(float fov, float aspectRatio, float near, float far) {
        return MatrixMakePerspective(fov, aspectRatio, near, far);
    }
}

