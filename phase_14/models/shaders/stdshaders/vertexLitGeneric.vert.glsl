#version 150

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file vertexLitGeneric.vert.glsl
 * @author Brian Lach
 * @date October 29, 2018
 *
 */

uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;
out vec4 l_position;

#if defined(NORMALMAP) || defined(HEIGHTMAP) || defined(SPHEREMAP)
in vec4 TANGENTNAME;
in vec4 BINORMALNAME;
#endif

#ifdef NORMALMAP
out vec4 l_tangent;
out vec4 l_binormal;
#endif

#ifdef NEED_COLOR
#ifdef COLOR_VERTEX
in vec4 p3d_Color;
out vec4 l_color;
#endif
#endif

#if defined(NEED_WORLD_POSITION) || defined(NEED_WORLD_NORMAL) || defined(HAS_SHADOW_SUNLIGHT)
uniform mat4 p3d_ModelMatrix;
#endif

#ifdef NEED_WORLD_POSITION
out vec4 l_worldPosition;
#endif

#ifdef NEED_WORLD_NORMAL
out vec4 l_worldNormal;
#endif

#ifdef NEED_EYE_POSITION
uniform mat4 p3d_ModelViewMatrix;
out vec4 l_eyePosition;
#elif defined(NORMALMAP)
uniform mat4 p3d_ModelViewMatrix;
#endif

#ifdef NEED_EYE_NORMAL
uniform mat4 tpose_view_to_model;
out vec4 l_eyeNormal;
#endif

#if defined(HEIGHTMAP) || defined(NEED_WORLD_NORMAL) || defined(NEED_EYE_NORMAL)
in vec3 p3d_Normal;
#endif

#if defined(HEIGHTMAP) || defined(SPHEREMAP)
uniform vec4 mspos_view;
out vec3 l_eyeVec;
#endif

in vec4 texcoord;
out vec4 l_texcoord;

#if defined(LIGHTING) && defined(BSP_LIGHTING)

uniform mat4 p3d_ViewMatrix;

// row 1: position
// row 2: direction
// row 3: attenuation
// row 4: color
uniform mat4 lightData[NUM_LIGHTS];
// transform world-space position and direction
// into view space for the fragment shader
out mat4 l_lightData[NUM_LIGHTS];

#endif

#ifdef HAS_SHADOW_SUNLIGHT
uniform mat4 pssmMVPs[PSSM_SPLITS];
uniform vec3 sunVector[1];
out vec4 l_pssmCoords[PSSM_SPLITS];
#endif

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
	finalNormal = (mat3)matrix * p3d_Normal;
	#endif

	#endif

	gl_Position = p3d_ModelViewProjectionMatrix * finalVertex;
	l_position = gl_Position;
    
    // pass through the texcoord input as-is
    l_texcoord = texcoord;

	#ifdef FOG
	l_hPos = l_position;
	#endif

	#ifdef NEED_WORLD_POSITION
	l_worldPosition = p3d_ModelMatrix * finalVertex;
	#endif

	#if defined(NEED_WORLD_NORMAL)
	l_worldNormal = p3d_ModelMatrix * vec4(finalNormal, 0);
	#endif

	#ifdef NEED_EYE_POSITION
	l_eyePosition = p3d_ModelViewMatrix * finalVertex;
	#endif

	#ifdef NEED_EYE_NORMAL
	l_eyeNormal.xyz = normalize(mat3(tpose_view_to_model) * finalNormal);
	l_eyeNormal.w = 0.0;
	#endif

	#ifdef NEED_COLOR
	#ifdef COLOR_VERTEX
	l_color = p3d_Color;
	#endif
	#endif

	#ifdef NORMALMAP
	l_tangent.xyz = normalize(mat3(p3d_ModelViewMatrix) * TANGENTNAME.xyz);
	l_tangent.w = 0.0;
	l_binormal.xyz = normalize(mat3(p3d_ModelViewMatrix) * -BINORMALNAME.xyz);
	l_binormal.w = 0.0;
	#endif
	
	// We define BSP light information in world-space,
    // but shader lighting calculations are done in eye-space.
	#if defined(LIGHTING) && defined(BSP_LIGHTING)
	for (int i = 0; i < NUM_LIGHTS; i++)
	{
		l_lightData[i] = lightData[i];

		// Transform world-space position and direction into view space
		// for the fragment shader
		l_lightData[i][0] = p3d_ViewMatrix * l_lightData[i][0];
		l_lightData[i][1] = normalize(p3d_ViewMatrix * l_lightData[i][1]);
	}
	#endif

	#if defined(HEIGHTMAP) || defined(SPHEREMAP) || defined(CUBEMAP)
	vec3 eyeDir = mspos_view.xyz - finalVertex.xyz;
	l_eyeVec.x = dot(p3d_Tangent.xyz, eyeDir);
	l_eyeVec.y = dot(p3d_Binormal.xyz, eyeDir);
	l_eyeVec.z = dot(finalNormal, eyeDir);
	l_eyeVec = normalize(l_eyeVec);
	#endif

	#ifdef HAS_SHADOW_SUNLIGHT
	vec4 lightclip;
	float push = clamp(dot(l_worldNormal.xyz, sunVector[0]), 0, 1) * NORMAL_OFFSET_SCALE;
	#ifndef NEED_WORLD_POSITION
	vec4 l_worldPosition = p3d_ModelMatrix * finalVertex;
	#endif

	for (int i = 0; i < PSSM_SPLITS; i++)
	{
		lightclip = pssmMVPs[i] * (l_worldPosition + (l_worldNormal * push));
		l_pssmCoords[i] = lightclip * vec4(0.5, 0.5, 0.5, 1.0) + lightclip.w * vec4(0.5, 0.5, 0.5, 0.0);
	}

	#endif
}