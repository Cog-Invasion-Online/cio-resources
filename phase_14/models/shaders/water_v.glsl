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
uniform vec4 wspos_view;
uniform mat4 p3d_ModelMatrix;
uniform mat4 p3d_ModelViewMatrix;
uniform mat4 p3d_ViewMatrixInverse;
uniform mat4 tpose_view_to_model;

in vec4 p3d_Vertex;
in vec4 p3d_Tangent;
in vec4 p3d_Binormal;
in vec3 p3d_Normal;

// These go to our pixel shader:
out vec4 texcoord0; // projected texture coordinates for the refraction and reflection textures
out vec2 texcoord1; // corrected texture coordinates for sampling the dudv map to distort texcoord0

out vec3 l_worldNormal;
out vec3 l_worldEyeToVert;
out mat3 l_tangentSpaceTranspose;

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
        
        vec4 worldPosition = p3d_ModelMatrix * p3d_Vertex;
        
        l_worldNormal = (p3d_ModelMatrix * vec4( p3d_Normal, 0.0 )).xyz;
        l_worldNormal = normalize(l_worldNormal);
        
        l_worldEyeToVert = (wspos_view - worldPosition).xyz;
        l_tangentSpaceTranspose[0] = mat3(p3d_ModelMatrix) * p3d_Tangent.xyz;
        l_tangentSpaceTranspose[1] = mat3(p3d_ModelMatrix) * -p3d_Binormal.xyz;
        l_tangentSpaceTranspose[2] = l_worldNormal;
}
