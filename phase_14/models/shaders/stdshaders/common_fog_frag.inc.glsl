/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file common_fog_frag.inc.glsl
 * @author Brian Lach
 * @date October 31, 2018
 *
 */
 
#pragma once

vec3 GetFogLinear(vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
	return mix(fogColor.rgb, result.rgb, clamp((fogData.z - hPos.z) * fogData.w, 0, 1));
}

vec3 GetFogExp(vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
	return mix(fogColor.rgb, result.rgb, clamp(exp2(fogData.x * hPos.z * -1.442695), 0, 1));
}

vec3 GetFogExpSqr(vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
	return mix(fogColor.rgb, result.rgb, clamp(exp2(fogData.x * fogData.x * hPos.z * hPos.z * -1.442695), 0, 1));
}

vec3 GetFog(int fogType, vec4 result, vec4 fogColor, vec4 hPos, float density, float start, float end, float scale)
{
    vec4 fogData = vec4(density, start, end, scale);

    if (fogType == 0)
    {
        return GetFogLinear(result, fogColor, hPos, fogData);
    }
    else if (fogType == 1)
    {
        return GetFogExp(result, fogColor, hPos, fogData);
    }
    else if (fogType == 2)
    {
        return GetFogExpSqr(result, fogColor, hPos, fogData);
    }

	return result.rgb;
}