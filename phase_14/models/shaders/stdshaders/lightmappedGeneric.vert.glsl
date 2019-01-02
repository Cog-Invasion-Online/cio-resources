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
 
//#ifdef BASETEXTURE
in vec4 texcoord;
out vec4 l_texcoordBaseTexture;
//#endif

#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
in vec2 TEXCOORD_LIGHTMAP;
out vec4 l_texcoordLightmap;
#endif

#if defined(BUMPMAP) || defined(BUMPED_LIGHTMAP) || defined(ENVMAP)
in vec3 p3d_Normal;
out vec3 l_normal;
#endif

#ifdef BUMPMAP
in vec3 p3d_Tangent;
in vec3 p3d_Binormal;
out vec4 l_tangent;
out vec4 l_binormal;
out vec4 l_texcoordBumpMap;
#endif

#if defined(ENVMAP)
uniform vec4 wspos_view;
out vec3 l_eyeVec;
uniform mat4 tpose_view_to_model;
out vec4 l_eyeNormal;
out vec3 l_eyeDir;
uniform mat4 p3d_ModelViewMatrix;
out vec4 l_worldNormal;
uniform mat4 p3d_ModelMatrix;
out vec4 l_worldEyePos;
out vec4 l_worldVertPos;
out vec4 l_worldEyeToVert;
#endif

#ifdef FOG
out vec4 l_hPos;
#endif

uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;

void main()
{
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    
    l_texcoordBaseTexture = texcoord;
    
#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
    l_texcoordLightmap = vec4(TEXCOORD_LIGHTMAP, 0, 0);
#endif
    
#ifdef BUMPMAP
    l_tangent = vec4(p3d_Tangent, 0.0);
    l_binormal = vec4(p3d_Binormal, 0.0);
	// Just use the base texture coord for the normal map.
	l_texcoordBumpMap = texcoord;
#endif
    
#if defined(BUMPMAP) || defined(BUMPED_LIGHTMAP) || defined(ENVMAP)
    l_normal = p3d_Normal;
#endif
    
#if defined(ENVMAP)
    l_worldEyePos = wspos_view;
    l_worldVertPos = p3d_ModelMatrix * p3d_Vertex;
    l_worldEyeToVert = l_worldEyePos - l_worldVertPos;
    l_worldNormal = p3d_ModelMatrix * vec4(p3d_Normal, 0);
    l_eyeVec = (p3d_ModelViewMatrix * p3d_Vertex).xyz;
    l_eyeDir = normalize(l_eyeVec);
    l_eyeNormal.xyz = normalize(mat3(tpose_view_to_model) * p3d_Normal);
    l_eyeNormal.w = 0.0;
#endif

#ifdef FOG
	l_hPos = gl_Position;
#endif
}
