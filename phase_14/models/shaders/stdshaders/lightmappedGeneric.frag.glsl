#version 150

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file lightmappedGeneric.frag.glsl
 * @author Brian Lach
 * @date November 02, 2018
 *
 * @desc Shader for lightmapped geometry (brushes, displacements).
 *
 */

//====================================================
// from mathlib.h

#define OO_SQRT_2 0.70710676908493042
#define OO_SQRT_3 0.57735025882720947
#define OO_SQRT_6 0.40824821591377258
// sqrt( 2 / 3 )
#define OO_SQRT_2_OVER_3 0.81649661064147949

#define NUM_BUMP_VECTS 3

vec3 g_localBumpBasis[3] = vec3[](
    vec3(OO_SQRT_2_OVER_3, 0.0f, OO_SQRT_3),
    vec3(-OO_SQRT_6, OO_SQRT_2, OO_SQRT_3),
    vec3(-OO_SQRT_6, -OO_SQRT_2, OO_SQRT_3)
);
//====================================================

#pragma include "phase_14/models/shaders/stdshaders/common_lighting_frag.inc.glsl"
 
#ifdef BASETEXTURE
uniform sampler2D baseTextureSampler;
in vec4 l_texcoordBaseTexture;
#endif

#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
in vec4 l_texcoordLightmap;
#endif

#if defined(FLAT_LIGHTMAP)
uniform sampler2D lightmapSampler;
#elif defined(BUMPED_LIGHTMAP)
uniform sampler2D lightmap0Sampler;
uniform sampler2D lightmap1Sampler;
uniform sampler2D lightmap2Sampler;
#endif

#ifdef SPHEREMAP
uniform struct
{
	float shininess;
} p3d_Material;

uniform sampler2D sphereSampler;
uniform mat4 p3d_ViewMatrixInverse;
in vec3 l_eyeVec;
in vec4 l_eyeNormal;
#endif

#ifdef NORMALMAP
uniform sampler2D normalSampler;
in vec4 l_texcoordNormalMap;
in vec4 l_tangent;
in vec4 l_binormal;
#endif

#if defined(NORMALMAP) || defined(BUMPED_LIGHTMAP)
in vec3 l_normal;
#endif

out vec4 outputColor;

void main()
{
    // start completely white, in case there is no base texture
    // again, why wouldn't there be one
    outputColor = vec4(1.0);
    
#ifdef BASETEXTURE
    outputColor = texture2D(baseTextureSampler, l_texcoordBaseTexture.xy);
#endif

#ifdef SPHEREMAP
    vec4 bumpedEyeNormal = l_eyeNormal;
#endif
#if defined(NORMALMAP) && defined(SPHEREMAP)
    GetBumpedNormal(bumpedEyeNormal, normalSampler, l_texcoordNormalMap, l_tangent, l_binormal);
#endif

#ifdef SPHEREMAP
    bumpedEyeNormal = normalize(bumpedEyeNormal);
    outputColor.rgb += SampleSphereMap(l_eyeVec, bumpedEyeNormal, p3d_ViewMatrixInverse,
                                  vec3(0), sphereSampler).rgb * p3d_Material.shininess;
#endif
  
#if defined(NORMALMAP) && defined(BUMPED_LIGHTMAP)
    // the normal for bumped lightmaps is in model space, not eye space
    vec3 msNormal = texture2D(normalSampler, l_texcoordNormalMap.xy).rgb * 2.0 - 1.0;
    msNormal = normalize(msNormal);
#elif defined(BUMPED_LIGHTMAP)
    // hmm, there is a bumped lightmap but no normal map.
    vec3 msNormal = l_normal;
#endif
    
#if defined(FLAT_LIGHTMAP)
    
    outputColor.rgb *= texture2D(lightmapSampler, l_texcoordLightmap.xy).rgb;
    
#elif defined(BUMPED_LIGHTMAP)
   
    vec3 dp = vec3(0);
    dp.x = clamp(dot(msNormal, g_localBumpBasis[0]), 0, 1);
    dp.y = clamp(dot(msNormal, g_localBumpBasis[1]), 0, 1);
    dp.z = clamp(dot(msNormal, g_localBumpBasis[2]), 0, 1);
    dp *= dp;
    
    vec3 lmColor0 = texture(lightmap0Sampler, l_texcoordLightmap.xy).rgb;
    vec3 lmColor1 = texture(lightmap1Sampler, l_texcoordLightmap.xy).rgb;
    vec3 lmColor2 = texture(lightmap2Sampler, l_texcoordLightmap.xy).rgb;
    
    float sum = dot(dp, vec3(1.0));
    
    vec3 finalLightmap = dp.x*lmColor0 + dp.y*lmColor1 + dp.z*lmColor2;
    finalLightmap *= 1.0 / sum;
    
    outputColor.rgb *= finalLightmap;
    
#endif
}