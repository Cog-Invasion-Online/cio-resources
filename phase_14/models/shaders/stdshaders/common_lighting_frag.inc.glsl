/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file common_lighting_frag.inc.glsl
 * @author Brian Lach
 * @date October 30, 2018
 *
 */
 
#pragma once

#pragma include "phase_14/models/shaders/stdshaders/common_shadows_frag.inc.glsl"

#define LIGHTTYPE_DIRECTIONAL	0
#define LIGHTTYPE_POINT			1
#define LIGHTTYPE_SPHERE		2
#define LIGHTTYPE_SPOT			3

vec3 GetDiffuseTerm(vec3 eyeSpaceLightVec, vec3 eyeSpaceNormal, bool halfLambert,
				    bool lightwarp, sampler2D lightwarpSampler)
{
	float result;
	float lintensity = dot(eyeSpaceNormal, eyeSpaceLightVec);

	if (halfLambert)
	{
		result = clamp(lintensity * 0.5 + 0.5, 0.0, 1.0);
		if (!lightwarp)
		{
			result *= result;
		}
	}
	else
	{
		result = clamp(lintensity, 0.0, 1.0);
	}

	vec3 vResult = vec3(result);
	if (lightwarp)
	{
		vResult = 2.0 * texture(lightwarpSampler, vec2(result, 0.5)).rgb;
	}

	return vResult;
}

vec3 GetPointLight(vec4 lpoint, vec4 latten, vec4 lcolor, inout float lattenv, inout vec3 lvec, 
				   vec4 eyePos, vec4 eyeNormal, bool halfLambert, bool lightwarp,
				   sampler2D lightwarpSampler)
{
	
	lvec = lpoint.xyz - eyePos.xyz;
	float ldist = length(lvec);
	lvec = normalize(lvec);
	
	vec3 vResult = GetDiffuseTerm(lvec, eyeNormal.xyz, halfLambert, lightwarp, lightwarpSampler);

	lattenv = ldist * latten.x;
	vec3 ratio = vResult / lattenv;

	vResult *= lcolor.rgb * ratio;
	
	return vResult;
}

vec3 GetSpotlight(vec4 lpoint, vec4 latten, vec4 lcolor, inout float lattenv, inout vec3 lvec, vec4 ldir,
                  vec4 eyePos, vec4 eyeNormal, bool halfLambert, bool lightwarp,
                  sampler2D lightwarpSampler)
{
    lvec = lpoint.xyz - eyePos.xyz;
    float ldist = length(lvec);
    lvec = normalize(lvec);
    vec3 vResult = GetDiffuseTerm(lvec, eyeNormal.xyz, halfLambert, lightwarp, lightwarpSampler); 
    
    float dot2 = clamp(dot(lvec, normalize(-ldir.xyz)), 0, 1);
    if (dot2 <= latten.z)
    {
        // outside light cone
        return vec3(0);
    }
    float denominator = ldist * latten.x;
    lattenv = vResult.x * dot2 / denominator;
    if (dot2 <= latten.y)
    {
        lattenv *= (dot2 - latten.z) / (latten.y - latten.z);
    }
    return lcolor.rgb * lattenv;
}

vec3 GetDirectionalLight(vec4 ldir, vec4 lcolor, vec4 eyeNormal, inout vec3 lvec, bool halfLambert,
						 bool lightwarp, sampler2D lightwarpSampler
                         #ifdef HAS_SHADOW_SUNLIGHT
                         , bool shadows, sampler2DArray shadowSampler, vec4 shadowCoords[PSSM_SPLITS]
                         #endif
                         )
{
	lvec = normalize(ldir.xyz);

	vec3 vResult = GetDiffuseTerm(lvec, eyeNormal.xyz, halfLambert, lightwarp, lightwarpSampler);
    
    #ifdef HAS_SHADOW_SUNLIGHT
	if (shadows)
	{
		float lshad = 0.0;
		GetSunShadow(lshad, shadowSampler, shadowCoords);
		vResult *= lshad;
	}
    #endif

	vResult *= lcolor.rgb;

	return vResult;
}

void RimTerm(inout vec4 totalRim, vec4 eyePos, vec4 eyeNormal, vec4 rimColor, float rimWidth)
{
	vec3 rimEyePos = normalize(-eyePos.xyz);
	float rIntensity = rimWidth - max(dot(rimEyePos, eyeNormal.xyz), 0.0);
	rIntensity = max(0.0, rIntensity);
	totalRim += vec4(rIntensity * rimColor);
}

float Fresnel(vec3 vNormal, vec3 vEyeDir)
{
    float fresnel = 1 - clamp(dot(vNormal, vEyeDir), 0, 1);
    return fresnel * fresnel;
}

float Fresnel4(vec3 vNormal, vec3 vEyeDir)
{
    float fresnel = 1 - clamp(dot(vNormal, vEyeDir), 0, 1);
    fresnel = fresnel * fresnel;
    return fresnel * fresnel;
}

void GetSpecular(float lattenv, vec4 eyeNormal,
				 vec4 eyePos, vec3 specularColor, float shininess, vec3 lightVec,
                 
                 inout vec3 olspec, bool doRim, float rimWidth, vec4 rimExponent, inout vec3 orim)
{
    vec3 rim = vec3(0);
    
	vec3 lhalf = normalize(lightVec - normalize(eyePos.xyz));
    float LdotR = max(dot(eyeNormal.xyz, lhalf), 0);

    if (shininess > 0.0)
    {
        vec3 lspec = specularColor;
        lspec *= lattenv;
        lspec *= pow(LdotR, shininess);
        olspec += lspec;
    }
    
	if (doRim)
    {
        rim = rimExponent.xyz;
        rim *= pow(max(0.0, rimWidth - LdotR), rimExponent.w);
        rim *= lattenv;
        orim += rim;
    }
}

void GetBumpedNormal(inout vec4 finalEyeNormal, sampler2D normalSampler, vec4 texcoord,
					 vec4 tangent, vec4 binormal)
{
	// Translate tangent-space normal in map to view-space.
	vec3 nSample = texture2D(normalSampler, texcoord.xy).rgb * 2.0 - 1.0;
	vec3 tsnormal = nSample + vec3(0.0, 0.0, 1.0);
	vec3 tmp = nSample * vec3(-2, -2, 2) + vec3(1, 1, -1);
	tsnormal = normalize(tsnormal * dot(tsnormal, tmp) - tmp * tsnormal.z);

	finalEyeNormal.xyz *= tsnormal.z;
	finalEyeNormal.xyz += tangent.xyz * tsnormal.x;
	finalEyeNormal.xyz += binormal.xyz * tsnormal.y;
}

vec3 CalcReflectionVectorNormalized(vec3 normal, vec3 eyeVector)
{
	return 2.0 * (dot(normal, eyeVector) / dot(normal, normal)) * normal - eyeVector;
}

vec2 GetSphereMapTexCoords(vec3 reflVec, mat4 invViewMatrix)
{
	// transform reflection vector into view space
	vec3 r = vec3(invViewMatrix * vec4(reflVec, 0.0));

    vec3 tmp = vec3(r.x, r.y, r.z + 1.0);
    float ooLen = dot(tmp, tmp);
    ooLen = 1.0 / sqrt(ooLen);
    
    tmp.x = ooLen * tmp.x + 1.0;
	tmp.y = ooLen * tmp.y + 1.0;
    
    return tmp.xy * 0.5;
}

vec4 SampleSphereMap(vec3 eyeVec, vec4 eyeNormal, mat4 invViewMatrix,
				   vec3 parallaxOffset, sampler2D sphereSampler)
{
	vec3 r = CalcReflectionVectorNormalized(eyeNormal.xyz, eyeVec);
    vec2 coords = GetSphereMapTexCoords(r, invViewMatrix) - parallaxOffset.xy;
    
	return texture2D(sphereSampler, coords);
}

vec4 SampleCubeMap(vec3 eyeVec, vec4 eyeNormal, vec3 parallaxOffset, sampler3D cubeSampler)
{
	vec3 cmR = reflect(eyeVec, eyeNormal.xyz);
	return texture(cubeSampler, cmR - parallaxOffset.xyz);
}

vec4 SampleAlbedo(vec4 texcoord, vec3 parallaxOffset, sampler2D albedoSampler)
{
	return texture2D(albedoSampler, texcoord.xy - parallaxOffset.xy);
}

bool AlphaTest(int type, float test, float ref)
{
	switch (type)
	{
	case 1:
		return true;
	case 2: // less
		return test >= ref;
	case 3: // equal
		return test != ref;
	case 4: // less equal
		return test > ref;
	case 5: // greater
		return test <= ref;
	case 6: // not equal
		return test == ref;
	case 7: // greater equal
		return test < ref;
	default:
		break;
	}

	return false;
}

bool ClipPlaneTest(vec4 worldPosition, vec4 clipPlane)
{
	return (worldPosition.x * clipPlane.x + worldPosition.y
			* clipPlane.y + worldPosition.z * clipPlane.z
			+ clipPlane.w <= 0.0);
}

vec3 AmbientCubeLight(vec3 worldNormal, vec3 ambientCube[6])
{
#if 0
	vec3 nSqr = worldNormal * worldNormal;
	int neg = 0;
	if (nSqr < 0)
	{
		neg = 1;
	}
	vec3 linear = nSqr.x * ambientCube[neg] +
        nSqr.y * ambientCube[neg + 2] +
        nSqr.z * ambientCube[neg + 4];
	return linear;
#endif

    vec3 linearColor;
    vec3 nSquared = worldNormal * worldNormal;
    vec3 isNegative = vec3(worldNormal.x < 0.0, worldNormal.y < 0.0, worldNormal.z < 0.0);
    vec3 isPositive = 1 - isNegative;
    
    isNegative *= nSquared;
    isPositive *= nSquared;
    
    linearColor = isPositive.x * ambientCube[0] + isNegative.x * ambientCube[1] +
				  isPositive.y * ambientCube[2] + isNegative.y * ambientCube[3] +
				  isPositive.z * ambientCube[4] + isNegative.z * ambientCube[5];
                  
    return linearColor;
}