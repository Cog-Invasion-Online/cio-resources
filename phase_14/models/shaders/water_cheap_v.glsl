/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file water_cheap_v.glsl
 * @author Brian Lach
 * @date March 22, 2019
 *
 * @desc Vertex shader for the water effects.
 */

#version 430

uniform mat4 p3d_ModelViewProjectionMatrix;
uniform vec4 wspos_view;
uniform mat4 p3d_ModelMatrix;

in vec4 p3d_Vertex;
in vec4 p3d_Tangent;
in vec4 p3d_Binormal;
in vec3 p3d_Normal;

// These go to our pixel shader:
out vec2 l_texcoord;

out vec3 l_worldNormal;
out vec3 l_worldEyeToVert;
out mat3 l_tangentSpaceTranspose;

// These are inputs from the game:
uniform float tex_scale; // controls scaling of dudv map

void main()
{
        gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
        
        l_texcoord = vec2( p3d_Vertex.x / 2.0 + 0.5, p3d_Vertex.y / 2.0 + 0.5 ) * tex_scale;
        
        vec4 worldPosition = p3d_ModelMatrix * p3d_Vertex;
        
        l_worldNormal = (p3d_ModelMatrix * vec4( p3d_Normal, 0.0 )).xyz;
        l_worldNormal = normalize(l_worldNormal);
        
        l_worldEyeToVert = (wspos_view - worldPosition).xyz;
        l_tangentSpaceTranspose[0] = mat3(p3d_ModelMatrix) * p3d_Tangent.xyz;
        l_tangentSpaceTranspose[1] = mat3(p3d_ModelMatrix) * -p3d_Binormal.xyz;
        l_tangentSpaceTranspose[2] = l_worldNormal;
}
