#version 330

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file vertexLitGeneric.vert.glsl
 * @author Brian Lach
 * @date October 29, 2018
 *
 */
 
#pragma include "phase_14/models/shaders/stdshaders/common_shadows_vert.inc.glsl"

uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;
out vec4 l_position;

#if defined(NEED_TBN) || defined(NEED_EYE_VEC) || defined(NEED_WORLD_NORMAL)
    in vec4 p3d_Tangent;
    in vec4 p3d_Binormal;
    out vec4 l_tangent;
    out vec4 l_binormal;
#endif

#ifdef NEED_COLOR
    #ifdef COLOR_VERTEX
        in vec4 p3d_Color;
        out vec4 l_color;
    #endif
#endif

#if defined(NEED_WORLD_POSITION) || defined(NEED_WORLD_NORMAL)
    uniform mat4 p3d_ModelMatrix;
#endif

#if defined(NEED_WORLD_POSITION)
    out vec4 l_worldPosition;
#endif

#ifdef NEED_WORLD_NORMAL
    out vec4 l_worldNormal;
    out mat3 l_tangentSpaceTranspose;
#endif

#ifdef NEED_EYE_POSITION
    uniform mat4 p3d_ModelViewMatrix;
    out vec4 l_eyePosition;
#elif defined(NEED_TBN)
    uniform mat4 p3d_ModelViewMatrix;
#endif

#ifdef NEED_EYE_NORMAL
    uniform mat4 tpose_view_to_model;
    out vec4 l_eyeNormal;
#endif

#if defined(NEED_WORLD_NORMAL) || defined(NEED_EYE_NORMAL)
    in vec3 p3d_Normal;
#endif

#ifdef NEED_EYE_VEC
    uniform vec4 mspos_view;
    out vec3 l_eyeVec;
    out vec3 l_eyeDir;
#endif

#ifdef NEED_WORLD_VEC
    uniform vec4 wspos_view;
    out vec4 l_worldEyeToVert;
#endif

in vec4 texcoord;
out vec4 l_texcoord;

#ifdef FOG
    out vec4 l_hPos;
#endif

#if defined(HARDWARE_SKINNING) && NUM_TRANSFORMS > 0
    uniform mat4 p3d_TransformTable[NUM_TRANSFORMS];
    in vec4 transform_weight;
    #ifdef INDEXED_TRANSFORMS
        in uvec4 transform_index;
    #endif
#endif

#ifdef HAS_SHADOW_SUNLIGHT
    uniform mat4 pssmMVPs[PSSM_SPLITS];
    uniform vec3 sunVector[1];
    out vec4 l_pssmCoords[PSSM_SPLITS];
#endif

void main()
{
	vec4 finalVertex = p3d_Vertex;

    #if defined(NEED_WORLD_NORMAL) || defined(NEED_EYE_NORMAL)
        vec3 finalNormal = p3d_Normal;
    #endif

    #if defined(HARDWARE_SKINNING) && NUM_TRANSFORMS > 0

        #ifndef INDEXED_TRANSFORMS
            const uvec4 transform_index = uvec4(0, 1, 2, 3);
        #endif

        mat4 matrix = p3d_TransformTable[transform_index.x] * transform_weight.x
        #if NUM_TRANSFORMS > 1
            + p3d_TransformTable[transform_index.y] * transform_weight.y
        #endif
        #if NUM_TRANSFORMS > 2
            + p3d_TransformTable[transform_index.z] * transform_weight.z
        #endif
        #if NUM_TRANSFORMS > 3
            + p3d_TransformTable[transform_index.w] * transform_weight.w
        #endif
        ;

        finalVertex = matrix * p3d_Vertex;
        #if defined(NEED_WORLD_NORMAL) || defined(NEED_EYE_NORMAL)
            finalNormal = mat3(matrix) * p3d_Normal;
        #endif

    #endif

	gl_Position = p3d_ModelViewProjectionMatrix * finalVertex;
	l_position = gl_Position;
    
    // pass through the texcoord input as-is
    l_texcoord = texcoord;

    #ifdef FOG
        l_hPos = l_position;
    #endif

    #if defined(NEED_WORLD_POSITION)
        l_worldPosition = p3d_ModelMatrix * finalVertex;
    #endif

    #ifdef NEED_WORLD_NORMAL
        l_worldNormal = p3d_ModelMatrix * vec4(finalNormal, 0);
        l_tangentSpaceTranspose[0] = mat3(p3d_ModelMatrix) * p3d_Tangent.xyz;
        l_tangentSpaceTranspose[1] = mat3(p3d_ModelMatrix) * -p3d_Binormal.xyz;
        l_tangentSpaceTranspose[2] = l_worldNormal.xyz;
    #endif

    #ifdef NEED_EYE_POSITION
        l_eyePosition = p3d_ModelViewMatrix * finalVertex;
    #endif

    #ifdef NEED_EYE_NORMAL
        l_eyeNormal = vec4(normalize(mat3(tpose_view_to_model) * finalNormal), 0.0);
    #endif

    #ifdef NEED_COLOR
        #ifdef COLOR_VERTEX
            l_color = p3d_Color;
        #endif
    #endif

    #ifdef NEED_TBN
        l_tangent = vec4(normalize(mat3(p3d_ModelViewMatrix) * p3d_Tangent.xyz), 0.0);
        l_binormal = vec4(normalize(mat3(p3d_ModelViewMatrix) * -p3d_Binormal.xyz), 0.0);
    #endif

    #ifdef NEED_EYE_VEC
        vec3 eyeDir = mspos_view.xyz - finalVertex.xyz;
        l_eyeVec = normalize(vec3(
			dot(p3d_Tangent.xyz, eyeDir),
			dot(p3d_Binormal.xyz, eyeDir),
			dot(finalNormal, eyeDir)
        ));
    #endif

    #ifdef NEED_WORLD_VEC
        l_worldEyeToVert = wspos_view - l_worldPosition;
    #endif

    #ifdef HAS_SHADOW_SUNLIGHT
        ComputeShadowPositions(l_worldNormal.xyz, l_worldPosition,
                               sunVector[0], pssmMVPs, l_pssmCoords);
    #endif
}
