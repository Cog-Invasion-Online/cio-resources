/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file water_v.glsl
 * @author Brian Lach
 * @date July 08, 2018
 *
 * @desc Vertex shader for the water effects.
 */

#version 430

uniform mat4 p3d_ModelViewProjectionMatrix;

in vec4 p3d_Vertex;

// These go to our pixel shader:
out vec4 texcoord0; // projected texture coordinates for the refraction and reflection textures
out vec2 texcoord1; // corrected texture coordinates for sampling the dudv map to distort texcoord0

// These are inputs from the game:
uniform float dudv_tile; // controls scaling of dudv map

void main()
{
        gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
        
        mat4 scale_mat = mat4(vec4(0.5, 0.0, 0.0, 0.0),
                              vec4(0.0, 0.5, 0.0, 0.0),
                              vec4(0.0, 0.0, 0.5, 0.0),
                              vec4(0.5, 0.5, 0.5, 1.0));
        texcoord0 = (scale_mat * p3d_ModelViewProjectionMatrix) * p3d_Vertex;
        
        texcoord1 = vec2( p3d_Vertex.x / 2.0 + 0.5, p3d_Vertex.y / 2.0 + 0.5 ) * dudv_tile;
}