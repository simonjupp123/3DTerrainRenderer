module camera_ogldev;

/*
        Copyright 2021 Etay Meiri

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or

    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// #include <GL/glew.h>
// #include <GLFW/glfw3.h>

import linear;
import bindbc.opengl;
import std.stdio;
import std.math;
import sdl_abstraction;
import bindbc.sdl;

// #include "ogldev_basic_glfw_camera.h"

static int MARGIN = 40;
static float EDGE_STEP = 0.5f;

class BasicCamera
{
    float m_speed = 40.0f;
    int m_windowWidth = 0;
    int m_windowHeight = 0;

    vec3 m_pos;
    vec3 m_up;
    vec3 m_target; /// This is on the camera axis

    bool m_OnUpperEdge;
    bool m_OnLowerEdge;
    bool m_OnLeftEdge;
    bool m_OnRightEdge;

    float m_AngleH = 0.0f;
    float m_AngleV = 0.0f;

    vec2 m_mousePos = vec2(0, 0);

    PersProjInfo m_persProjInfo;
    mat4 m_projection;

    this()
    {
        m_pos = vec3(0.0f, 0.0f, 0.0f);
        m_target = vec3(0.0f, 0.0f, 1.0f);
        m_up = vec3(0.0f, 1.0f, 0.0f);
        InitInternal();

    }

    this(int WindowWidth, int WindowHeight)
    {

        m_windowWidth = WindowWidth;
        m_windowHeight = WindowHeight;
        m_pos = vec3(0.0f, 0.0f, 0.0f);
        m_target = vec3(0.0f, 0.0f, 1.0f);
        m_up = vec3(0.0f, 1.0f, 0.0f);
        InitInternal();

    }

    this(const PersProjInfo persProjInfo, const vec3 Pos, const vec3 Target, const vec3 Up)
    {
        InitCamera(persProjInfo, Pos, Target, Up);
    }

    void SetPosition(float x, float y, float z)
    {
        m_pos.x = x;
        m_pos.y = y;
        m_pos.z = z;
    }

    void SetPosition(const vec3 pos)
    {
        SetPosition(pos.x, pos.y, pos.z);
    }

    void InitCamera(const PersProjInfo persProjInfo, const vec3 Pos, const vec3 Target, const vec3 Up)
    {
        m_persProjInfo = persProjInfo;
        m_projection.InitPersProjTransform(persProjInfo);
        m_windowWidth = cast(int) persProjInfo.Width;
        m_windowHeight = cast(int) persProjInfo.Height;
        m_pos = Pos;

        m_target = Target;
        m_target.Normalize();

        m_up = Up;
        m_up.Normalize();

        InitInternal();
    }

    // void BasicCamera::InitCamera(const OrthoProjInfo& orthoProjInfo, const Vector3f& Pos, const Vector3f& Target, const Vector3f& Up)
    // {
    //     m_projection.InitOrthoProjTransform(orthoProjInfo);
    //     m_windowWidth = (int)orthoProjInfo.Width;
    //     m_windowHeight = (int)orthoProjInfo.Height;
    //     m_pos = Pos;

    //     m_target = Target;
    //     m_target.Normalize();

    //     m_up = Up;
    //     m_up.Normalize();

    //     InitInternal();
    // }

    void InitInternal()
    {
        // vec3 HTarget(m_target.x, 0.0, m_target.z);
        // HTarget.Normalize();

        m_AngleH = -(atan2(m_target.z, m_target.x)).ToAngle;

        m_AngleV = -(asin(m_target.y)).ToAngle;

        m_OnUpperEdge = false;
        m_OnLowerEdge = false;
        m_OnLeftEdge = false;
        m_OnRightEdge = false;
        m_mousePos.x = m_windowWidth / 2;
        m_mousePos.y = m_windowHeight / 2;
    }

    void SetTarget(float x, float y, float z)
    {
        m_target.x = x;
        m_target.y = y;
        m_target.z = z;

        InitInternal();
    }

    void SetTarget(const vec3 target)
    {
        SetTarget(target.x, target.y, target.z);
    }

    bool OnKeyboard(int Key)
    {
        const float mouse_change = 0.5f;
        bool CameraChangedPos = false;

        switch (Key)
        {

        case SDLK_w:
            m_pos = m_pos + (m_target * m_speed);
            CameraChangedPos = true;
            break;

        case SDLK_s:
            m_pos = m_pos - (m_target * m_speed);
            CameraChangedPos = true;
            break;

        case SDLK_a:
            {
                vec3 Left = m_target.Cross(m_up);
                Left.Normalize();
                Left = Left * m_speed;
                m_pos = m_pos + Left;
                CameraChangedPos = true;
            }
            break;

        case SDLK_d:
            {
                vec3 Right = m_up.Cross(m_target);
                Right.Normalize();
                Right = Right * m_speed;
                m_pos = m_pos + Right;
                CameraChangedPos = true;
            }
            break;

        case SDLK_UP:
            m_AngleV = m_AngleV + mouse_change;
            Update();
            break;

        case SDLK_DOWN:
            m_AngleV = m_AngleV - mouse_change;
            Update();
            break;

        case SDLK_LEFT:
            m_AngleH = m_AngleH - mouse_change;
            Update();
            break;

        case SDLK_RIGHT:
            m_AngleH = m_AngleH + mouse_change;
            Update();
            break;

            // case GLFW_KEY_PAGE_UP:
            //     m_pos.y += m_speed;
            //     CameraChangedPos = true;
            //     break;

            // case GLFW_KEY_PAGE_DOWN:
            //     m_pos.y -= m_speed;
            //     CameraChangedPos = true;
            //     break;

        case SDLK_EQUALS:
            m_speed += 0.5f;
            printf("Speed changed to %f\n", m_speed);
            break;

        case SDLK_MINUS:
            m_speed -= 0.5f;
            if (m_speed < 0.1f)
            {
                m_speed = 0.1f;
            }
            printf("Speed changed to %f\n", m_speed);
            break;

        case SDLK_c:
            printf("Camera pos: ");
            writeln(m_pos);
            printf("\n");
            printf("Camera target: ");
            writeln(m_target);
            printf("\n");
            break;

        default:
            break;
        }

        if (CameraChangedPos)
        {
            //        printf("Camera pos: "); m_pos.Print(); printf("\n");
        }

        return CameraChangedPos;
    }

    void OnMouse(int x, int y)
    {
        int DeltaX = x - cast(int) m_mousePos.x;
        int DeltaY = y - cast(int) m_mousePos.y;

        m_mousePos.x = x;
        m_mousePos.y = y;

        m_AngleH -= cast(float) DeltaX / 200.0f;
        m_AngleV -= cast(float) DeltaY / 200.0f;

        if (x <= MARGIN)
        {
            m_OnLeftEdge = true;
            m_OnRightEdge = false;
        }
        else if (x >= (m_windowWidth - MARGIN))
        {
            m_OnRightEdge = true;
            m_OnLeftEdge = false;
        }
        else
        {
            m_OnLeftEdge = false;
            m_OnRightEdge = false;
        }

        if (y <= MARGIN)
        {
            m_OnUpperEdge = true;
            m_OnLowerEdge = false;
        }
        else if (y >= (m_windowHeight - MARGIN))
        {
            m_OnLowerEdge = true;
            m_OnUpperEdge = false;
        }
        else
        {
            m_OnUpperEdge = false;
            m_OnLowerEdge = false;
        }

        Update();
    }

    void UpdateMousePosSilent(int x, int y)
    {
        m_mousePos.x = x;
        m_mousePos.y = y;
    }

    void OnRender()
    {
        bool ShouldUpdate = false;

        if (m_OnLeftEdge)
        {
            m_AngleH -= EDGE_STEP;
            ShouldUpdate = true;
        }
        else if (m_OnRightEdge)
        {
            m_AngleH += EDGE_STEP;
            ShouldUpdate = true;
        }

        if (m_OnUpperEdge)
        {
            if (m_AngleV > -90.0f)
            {
                m_AngleV -= EDGE_STEP;
                ShouldUpdate = true;
            }
        }
        else if (m_OnLowerEdge)
        {
            if (m_AngleV < 90.0f)
            {
                m_AngleV += EDGE_STEP;
                ShouldUpdate = true;
            }
        }

        if (ShouldUpdate)
        {
            Update();
        }
    }

    void Update()
    {
        vec3 Yaxis = vec3(0.0f, 1.0f, 0.0f);

        // Rotate the view vector by the horizontal angle around the vertical axis
        vec3 View = vec3(1.0f, 0.0f, 0.0f);
        View.Rotate(m_AngleH, Yaxis);
        View.Normalize();

        // Rotate the view vector by the vertical angle around the horizontal axis
        vec3 U = Yaxis.Cross(View);
        U.Normalize();
        View.Rotate(m_AngleV, U);

        m_target = View;
        m_target.Normalize();

        m_up = m_target.Cross(U);
        m_up.Normalize();
    }

    mat4 GetMatrix()
    {
        mat4 CameraTransformation;
        CameraTransformation.InitCameraTransform(m_pos, m_target, m_up);
        return CameraTransformation;
    }
    

    mat4 GetViewProjMatrix()
    {
        mat4 View = GetMatrix();
        mat4 Projection = m_projection;
        mat4 ViewProj = Projection * View;
        return ViewProj;
    }


    mat4 GetViewportMatrix()
    {
        float HalfW = m_windowWidth / 2.0f;
        float HalfH = m_windowHeight / 2.0f;

        mat4 Viewport = mat4(HalfW, 0.0f, 0.0f, HalfW,
            0.0f, HalfH, 0.0f, HalfH,
            0.0f, 0.0f, 1.0f, 0.0f,
            0.0f, 0.0f, 0.0f, 1.0f);

        return Viewport;
    }

}

// BasicCamera::BasicCamera(const OrthoProjInfo& orthoProjInfo, const Vector3f& Pos, const Vector3f& Target, const Vector3f& Up)
// {
//     InitCamera(orthoProjInfo, Pos, Target, Up);
// }
