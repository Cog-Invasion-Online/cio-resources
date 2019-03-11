#version 330

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
 
#pragma optionNV(unroll all)
 
#pragma include "phase_14/models/shaders/stdshaders/common_shadows_vert.inc.glsl"
 
in vec4 texcoord;
out vec4 l_texcoordBaseTexture;

#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
    in vec2 TEXCOORD_LIGHTMAP;
    out vec4 l_texcoordLightmap;
#endif

#if defined(BUMPMAP) || defined(BUMPED_LIGHTMAP) || defined(ENVMAP) || defined(HAS_SHADOW_SUNLIGHT)
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

#if defined(ENVMAP) || defined(HAS_SHADOW_SUNLIGHT)
    uniform mat4 p3d_ModelMatrix;
    out vec4 l_worldNormal;
#endif

#if defined(ENVMAP)
    uniform vec4 wspos_view;
    out vec4 l_worldEyeToVert;
    #ifdef BUMPMAP
        out mat3 l_tangentSpaceTranspose;
    #endif
#endif

#ifdef FOG
    out vec4 l_hPos;
#endif

#ifdef HAS_SHADOW_SUNLIGHT
    uniform mat4 pssmMVPs[PSSM_SPLITS];
    uniform vec3 sunVector[1];
    out vec4 l_pssmCoords[PSSM_SPLITS];
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
    
    #if defined(BUMPMAP) || defined(BUMPED_LIGHTMAP)
        l_normal = p3d_Normal;
    #endif
    
    #if defined(ENVMAP) || defined(HAS_SHADOW_SUNLIGHT)
        vec4 worldPos = p3d_ModelMatrix * p3d_Vertex;
        l_worldNormal = p3d_ModelMatrix * vec4(p3d_Normal, 0);
    #endif
    
    #if defined(ENVMAP)
        l_worldEyeToVert = wspos_view - worldPos;
        #ifdef BUMPMAP
            l_tangentSpaceTranspose[0] = mat3(p3d_ModelMatrix) * p3d_Tangent.xyz;
            l_tangentSpaceTranspose[1] = mat3(p3d_ModelMatrix) * -p3d_Binormal.xyz;
            l_tangentSpaceTranspose[2] = l_worldNormal.xyz;
        #endif
    #endif

    #ifdef FOG
        l_hPos = gl_Position;
    #endif
    
    #ifdef HAS_SHADOW_SUNLIGHT
        ComputeShadowPositions(l_worldNormal.xyz, worldPos,
                               sunVector[0], pssmMVPs, l_pssmCoords);
    #endif
}
