/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file hdr_exposure_v.glsl
 * @author Brian Lach
 * @date May 30, 2018
 *
 * @desc Determines exposure level of scene.
 */
 
//GLSL

#version 330

uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;
in vec2 p3d_MultiTexCoord0;

out vec2 uv;

void main()
{
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    uv = p3d_MultiTexCoord0;
}
