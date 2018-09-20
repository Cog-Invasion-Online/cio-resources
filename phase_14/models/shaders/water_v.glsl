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
uniform vec4 mspos_view;
uniform mat4 p3d_ModelMatrix;
uniform mat4 p3d_ModelViewMatrix;
uniform mat4 p3d_ViewMatrixInverse;
uniform mat4 tpose_view_to_model;

in vec4 p3d_Vertex;
in vec3 p3d_Normal;

// These go to our pixel shader:
out vec4 texcoord0; // projected texture coordinates for the refraction and reflection textures
out vec2 texcoord1; // corrected texture coordinates for sampling the dudv map to distort texcoord0
//out vec2 texcoord2; // envmap coords
out vec3 eye_vec; // direction of camera to vertex

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
        
        vec4 eye_normal;
        eye_normal.xyz = normalize(mat3(tpose_view_to_model) * p3d_Normal);
        eye_normal.w = 0.0;
        
        //vec3 world_normal = (p3d_ModelMatrix * vec4( p3d_Normal, 0.0 )).xyz;
        //world_normal = normalize(world_normal);
        
        //vec3 eye_pos = vec3(p3d_ModelViewMatrix * p3d_Vertex);
        //vec3 eye_vec = normalize(eye_pos);
        //vec3 r = reflect(eye_vec, eye_normal.xyz);
        //r = vec3(p3d_ViewMatrixInverse * vec4(r, 0.0));
        //float m = 2.0 * sqrt(pow(r.x, 2.0) + pow(r.y, 2.0) + pow(r.z + 1.0, 2.0));
        //texcoord2.x = (r.x / m) + 0.5;
        //texcoord2.y = (r.y / m) + 0.5;
        
        eye_vec = normalize( mspos_view.xyz - p3d_Vertex.xyz );
}