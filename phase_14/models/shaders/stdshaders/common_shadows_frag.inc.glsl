/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file common_shadows_frag.inc.glsl
 * @author Brian Lach
 * @date October 30, 2018
 *
 */
 
#pragma once

#ifndef PSSM_SPLITS
#define PSSM_SPLITS 3
#define SHADOW_BLUR 1.5
#define DEPTH_BIAS 0.0001
#endif

#define DO_POISSON 1

#define NUM_POISSON 14
//const vec2 poissonDisk[NUM_POISSON] = vec2[](
//    vec2( 0.0, 0.0 ),
//	vec2( -.326, -.406 ), vec2( -.840, -.074 ), vec2( -.696, .457 ),
//    vec2( -.203, .621 ), vec2( .962, -.195 ), vec2( .473, -.480 ),
//    vec2( .519, .767 ), vec2( .185, -.893 ), vec2( .507, .064 ),
//    vec2( .896, .412 ), vec2( -.322, -.933 ), vec2( -.792, -.598 )
//);
const vec2 poissonDisk[NUM_POISSON] = vec2[](
	vec2(0.0, 0.0),
	vec2(-0.9328896, -0.03145855), // left check offset
    vec2(0.8162807, -0.05964844), // right check offset
    vec2(-0.184551, 0.9722522), // top check offset
    vec2(0.04031969, -0.8589798), // bottom check offset
    vec2(-0.54316, 0.21186), vec2(-0.039245, -0.34345), vec2(0.076953, 0.40667),
    vec2(-0.66378, -0.54068), vec2(-0.54130, 0.66730), vec2(0.69301, 0.46990),
    vec2(0.37228, 0.038106), vec2(0.28597, 0.80228), vec2(0.44801, -0.43844)
);

int FindCascade(vec4 shadowCoords[PSSM_SPLITS], inout vec3 proj, inout float depthCmp)
{
	for (int i = 0; i < PSSM_SPLITS; i++)
	{
		proj = shadowCoords[i].xyz;
		if (proj.x >= 0.0 && proj.x <= 1.0 && proj.y >= 0.0 && proj.y <= 1.0)
		{
			depthCmp = proj.z - DEPTH_BIAS;
			return i;
		}
	}
}

float SampleCascade(sampler2DArray shadowSampler, vec3 proj, float depthCmp, int cascade, int diskIdx)
{
	float val = texture(shadowSampler, vec3(proj.x + (poissonDisk[diskIdx].x * SHADOW_BLUR),
										    proj.y + (poissonDisk[diskIdx].y * SHADOW_BLUR), cascade)).r;
	return step(depthCmp, val);
}

void GetSunShadow(inout float lshad, sampler2DArray shadowSampler, vec4 shadowCoords[PSSM_SPLITS], vec3 lightDir, vec3 eyeNormal)
{	
	lshad = 0.0;
	
	// We can guarantee that the pixel is in shadow if
	// it's facing away from the light source.
	//
	// This is a good optimization, but will only look
	// correct if we are using unmodified lambert shading.
	// Lightwarps and half-lambert modify the lambertian term.
	//
	// We also only do this outside of BSP levels. Doing this in BSP
	// levels will cause brush faces facing away from the fake shadows
	// to be dark.
	#if !defined(LIGHTWARP) && !defined(HALFLAMBERT) && !defined(BSP_LIGHTING) && !defined(BUMPED_LIGHTMAP) && !defined(FLAT_LIGHTMAP)
		if (dot(eyeNormal, lightDir) < 0.0)
			return;
	#endif
	
	vec3 proj = vec3(0);
	float depthCmp = 0.0;
	int cascade = FindCascade(shadowCoords, proj, depthCmp);
	lshad += SampleCascade(shadowSampler, proj, depthCmp, cascade, 0);
	
	#if DO_POISSON
		lshad += SampleCascade(shadowSampler, proj, depthCmp, cascade, 1);
		lshad += SampleCascade(shadowSampler, proj, depthCmp, cascade, 2);
		lshad += SampleCascade(shadowSampler, proj, depthCmp, cascade, 3);
		lshad += SampleCascade(shadowSampler, proj, depthCmp, cascade, 4);
		
		if (lshad > 0.1 && lshad < 4.9)
		{
			// pixel was not totally in light or totally in shadow
			// do more samples
			for (int i = 5; i < NUM_POISSON; i++)
			{
				lshad += SampleCascade(shadowSampler, proj, depthCmp, cascade, i);
			}
			
			lshad /= NUM_POISSON;
			return;
		}

		lshad /= 5;
	#endif
}

void DoBlendShadow(inout vec3 diffuseLighting, sampler2DArray shadowSampler,
                   vec4 shadowCoords[PSSM_SPLITS], vec3 lightDir, vec3 eyeNormal,
                   vec3 ambientLightIdentifier, vec3 ambientLightMin, float ambientLightScale)
{
    float shadow = 0.0;
    GetSunShadow(shadow, shadowSampler, shadowCoords, lightDir, eyeNormal);
    shadow = 1.0 - shadow;
    
    vec3 lightDelta = diffuseLighting - ambientLightMin;
    lightDelta -= dot(ambientLightIdentifier, lightDelta) * ambientLightIdentifier;
    float shadowMask = lightDelta.x * lightDelta.x + lightDelta.y * lightDelta.y + lightDelta.z * lightDelta.z;
    shadowMask = 1.0 - clamp(shadowMask * ambientLightScale, 0, 1);
    
    diffuseLighting = min(diffuseLighting, mix(diffuseLighting, ambientLightMin, shadow * shadowMask));
}
