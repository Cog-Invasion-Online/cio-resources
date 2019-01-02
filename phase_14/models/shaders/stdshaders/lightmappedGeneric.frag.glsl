#version 330

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
 
#pragma include "phase_14/models/shaders/stdshaders/common_fog_frag.inc.glsl"

#ifdef FOG
in vec4 l_hPos;
uniform struct
{
	vec4 color;
	float density;
	float start;
	float end;
	float scale;
} p3d_Fog;
#endif

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

vec3 LightmapSample(sampler2DArray lightmapSampler, vec2 coords, int page)
{
    return texture(lightmapSampler, vec3(coords.x, coords.y, page)).rgb;
}
 
#ifdef BASETEXTURE
uniform sampler2D baseTextureSampler;
#endif

in vec4 l_texcoordBaseTexture;

#if defined(FLAT_LIGHTMAP) || defined(BUMPED_LIGHTMAP)
in vec4 l_texcoordLightmap;
uniform sampler2DArray lightmapSampler;
#endif

#if defined(ENVMAP)

uniform samplerCube envmapSampler;
uniform vec3 envmapTint;
uniform vec3 envmapContrast;
uniform vec3 envmapSaturation;

#ifdef ENVMAP_MASK
uniform sampler2D envmapMaskSampler;
#endif

uniform mat4 p3d_ViewMatrixInverse;
in vec3 l_eyeVec;
in vec4 l_eyeNormal;
in vec3 l_eyeDir;
in vec4 l_worldNormal;
in vec4 l_worldEyePos;
in vec4 l_worldVertPos;
in vec4 l_worldEyeToVert;
#endif

#ifdef BUMPMAP
uniform sampler2D bumpSampler;
in vec4 l_texcoordBumpMap;
in vec4 l_tangent;
in vec4 l_binormal;
#endif

#if defined(BUMPMAP) || defined(BUMPED_LIGHTMAP) || defined(ENVMAP)
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

#if defined(ENVMAP)
    vec4 bumpedEyeNormal = l_eyeNormal;
#endif
#if defined(BUMPMAP) && defined(ENVMAP)
    GetBumpedNormal(bumpedEyeNormal, bumpSampler, l_texcoordBumpMap, l_tangent, l_binormal);
#endif
  
#if defined(BUMPMAP) && defined(BUMPED_LIGHTMAP)
    // the normal for bumped lightmaps is in model space, not eye space
    vec3 msNormal = texture2D(bumpSampler, l_texcoordBumpMap.xy).rgb * 2.0 - 1.0;
    msNormal = normalize(msNormal);
#elif defined(BUMPED_LIGHTMAP)
    // hmm, there is a bumped lightmap but no normal map.
    vec3 msNormal = l_normal;
#endif
    
#if defined(FLAT_LIGHTMAP)
    
    outputColor.rgb *= LightmapSample(lightmapSampler, l_texcoordLightmap.xy, 0);
    
#elif defined(BUMPED_LIGHTMAP)
   
    vec3 dp = vec3(0);
    dp.x = clamp(dot(msNormal, g_localBumpBasis[0]), 0, 1);
    dp.y = clamp(dot(msNormal, g_localBumpBasis[1]), 0, 1);
    dp.z = clamp(dot(msNormal, g_localBumpBasis[2]), 0, 1);
    dp *= dp;
    
    vec3 lmColor0 = LightmapSample(lightmapSampler, l_texcoordLightmap.xy, 1);
    vec3 lmColor1 = LightmapSample(lightmapSampler, l_texcoordLightmap.xy, 2);
    vec3 lmColor2 = LightmapSample(lightmapSampler, l_texcoordLightmap.xy, 3);
    
    float sum = dot(dp, vec3(1.0));
    
    vec3 finalLightmap = dp.x*lmColor0 + dp.y*lmColor1 + dp.z*lmColor2;
    finalLightmap *= 1.0 / sum;
    
    outputColor.rgb *= finalLightmap;
    
#endif

//#ifdef SPHEREMAP
//    bumpedEyeNormal = normalize(bumpedEyeNormal);
//    outputColor.rgb += SampleSphereMap(l_eyeVec, bumpedEyeNormal, p3d_ViewMatrixInverse,
//                                  vec3(0), sphereSampler).rgb * p3d_Material.shininess * Fresnel4(bumpedEyeNormal.xyz, l_eyeVec.xyz);
//#endif

#ifdef ENVMAP
    bumpedEyeNormal = normalize(bumpedEyeNormal);
    vec3 spec = SampleCubeMap(l_worldEyeToVert.xyz, l_worldNormal,
							  p3d_ViewMatrixInverse, vec3(0), envmapSampler).rgb;
							  
	#ifdef ENVMAP_MASK
	spec *= texture2D(envmapMaskSampler, l_texcoordBaseTexture.xy).rgb;
	#endif
	
	spec *= envmapTint;
	
	// saturation and contrast
	vec3 specSqr = spec * spec;
	spec = mix(spec, specSqr, envmapContrast);
	vec3 greyScale = vec3(dot(spec, vec3(.299, .587, .114)));
	spec = mix(greyScale, spec, envmapSaturation);
	
	// calc fresnel factor
	vec3 eyeVec = normalize(l_worldEyeToVert.xyz);
	//float fresnel = 1.0 - dot(l_worldNormal.xyz, eyeVec);
	//fresnel = pow(fresnel, 5.0);
	spec *= Fresnel(l_worldNormal.xyz, eyeVec);
    
    outputColor.rgb += spec;
        
#endif

#ifdef FOG
	// Apply fog.
	outputColor.rgb = GetFog(FOG, outputColor, p3d_Fog.color, l_hPos, p3d_Fog.density,
						p3d_Fog.start, p3d_Fog.end, p3d_Fog.scale);
#endif

#ifndef HDR
    outputColor.rgb = clamp(outputColor.rgb, 0.0, 1.0);
#endif

	//outputColor.rgb = l_texcoordBaseTexture.rgb;
}
