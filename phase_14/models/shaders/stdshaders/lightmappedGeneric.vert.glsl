#version 150

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file lightmappedGeneric.vert.glsl
 * @author Brian Lach
 * @date November 02, 2018
 *
 * @desc Shader for lightmapped geometry (brushes, displacements).
 *
 */
 
#ifdef BASETEXTURE
in vec4 texcoord_basetexture;
out vec4 l_texcoordBaseTexture;
#endif

#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
in vec4 texcoord_lightmap;
out vec4 l_texcoordLightmap;
#endif

#if defined(NORMALMAP) || defined(SPHEREMAP) || defined(BUMPED_LIGHTMAP)
in vec3 p3d_Normal;
#endif

#if defined(NORMALMAP) || defined(BUMPED_LIGHTMAP)
out vec3 l_normal;
#endif

#ifdef NORMALMAP

#ifndef BASETEXTURE
in vec4 texcoord_basetexture; // use base texture coordinates for normal map
                              // those coordinates should exist even if there is
                              // no base texture (idk why there wouldn't be one though)
#endif

in vec3 p3d_Tangent;
in vec3 p3d_Binormal;
out vec4 l_tangent;
out vec4 l_binormal;
out vec4 l_texcoordNormalMap;
#endif

#ifdef SPHEREMAP
in vec4 mspos_view;
out vec3 l_eyeVec;
uniform mat4 tpose_view_to_model;
out vec4 l_eyeNormal;
#endif

uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;

void main()
{
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    
#ifdef BASETEXTURE
    l_texcoordBaseTexture = texcoord_basetexture;
#endif
    
#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
    l_texcoordLightmap = texcoord_lightmap;
#endif
    
#ifdef NORMALMAP
    l_tangent = vec4(p3d_Tangent, 0.0);
    l_binormal = vec4(p3d_Binormal, 0.0);
    l_texcoordNormalMap = texcoord_basetexture;
#endif
    
#if defined(NORMALMAP) || defined(BUMPED_LIGHTMAP)
    l_normal = p3d_Normal;
#endif
    
#ifdef SPHEREMAP
    l_eyeVec = mspos_view.xyz - p3d_Vertex.xyz;
    l_eyeNormal.xyz = normalize(mat3(tpose_view_to_model) * p3d_Normal);
    l_eyeNormal.w = 0.0;
#endif
}