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

#define NUM_POISSON 13
vec2 poissonDisk[NUM_POISSON] = vec2[](
    vec2( 0.0, 0.0 ),
	vec2( -.326, -.406 ), vec2( -.840, -.074 ), vec2( -.696, .457 ),
    vec2( -.203, .621 ), vec2( .962, -.195 ), vec2( .473, -.480 ),
    vec2( .519, .767 ), vec2( .185, -.893 ), vec2( .507, .064 ),
    vec2( .896, .412 ), vec2( -.322, -.933 ), vec2( -.792, -.598 )
);

void GetSunShadow(inout float lshad, sampler2DArray shadowSampler, vec4 shadowCoords[PSSM_SPLITS])
{
	lshad = 0.0;
	float shadowBlur = SHADOW_BLUR;
	int j, k;
	for (j = 0; j < PSSM_SPLITS; j++)
	{
		vec3 proj = shadowCoords[j].xyz / shadowCoords[j].w;
		if (proj.x >= 0.0 && proj.x <= 1.0 && proj.y >= 0.0 && proj.y <= 1.0)
		{
			float depthCmp = proj.z - DEPTH_BIAS;
			float val;
			for (k = 0; k < NUM_POISSON; k++)
			{
				val = texture(shadowSampler, vec3(proj.x + (poissonDisk[k].x * shadowBlur),
												  proj.y + (poissonDisk[k].y * shadowBlur), j)).r;
				if (val > depthCmp) { lshad++; }
			}
			lshad /= NUM_POISSON;
			break;
		}
	}
}