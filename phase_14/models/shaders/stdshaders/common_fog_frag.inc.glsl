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

void GetFogLinear(inout vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
	mix(fogColor.rgb, result.rgb, clamp((fogData.z - hPos.z) * fogData.w, 0, 1));
}

void GetFogExp(inout vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
	mix(fogColor.rgb, result.rgb, clamp(exp2(fogData.x * hPos.z * -1.442695), 0, 1));
}

void GetFogExpSqr(inout vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
	mix(fogColor.rgb, result.rgb, clamp(exp2(fogData.x * fogData.x * hPos.z * hPos.z * -1.442695), 0, 1));
}

void GetFog(int fogType, inout vec4 result, vec4 fogColor, vec4 hPos, vec4 fogData)
{
    if (fogType == 0)
    {
        GetFogLinear(result, fogColor, hPos, fogData);
    }
    else if (fogType == 1)
    {
        GetFogExp(result, fogColor, hPos, fogData);
    }
    else if (fogType == 2)
    {
        GetFogExpSqr(result, fogColor, hPos, fogData);
    }
}