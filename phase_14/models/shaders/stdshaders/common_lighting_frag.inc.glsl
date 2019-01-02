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

float GetFalloff(vec4 falloff, vec4 falloff2, float dist)
{
    float falloffevaldist = min(dist * 16.0, falloff2.z);
    
    float lattenv = falloffevaldist * falloffevaldist;
    lattenv *= falloff.z;                   // quadratic
    lattenv += falloff.y * falloffevaldist; // linear
    lattenv += falloff.x;                   // constant
    lattenv = 1.0 / lattenv;
    
    return lattenv;
}

bool HasHardFalloff(vec4 falloff2)
{
    return (falloff2.y > falloff2.x);
}

bool CheckHardFalloff(vec4 falloff2, float dist, float dot)
{
    if (dist * 16.0 > falloff2.y)
    {
        return false;
    }
    
    return true;
}

void ApplyHardFalloff(inout float falloff, vec4 falloff2, float dist, float dot)
{
    float t = falloff2.y - falloff2.x;
    t /= (dist * 16.0) - falloff2.x;
    
    t = clamp(t, 0, 1);
    t -= 1.0;
    
    float mult = t * t * t *( t * ( t* 6.0 - 15.0 ) + 10.0 );
    
    falloff *= mult;
}

vec3 GetPointLight(vec4 lpoint, vec4 latten, vec4 lcolor, inout float lattenv, inout vec3 lvec,
                   vec4 falloff2, vec4 falloff3,
				   vec4 eyePos, vec4 eyeNormal, bool halfLambert, bool lightwarp,
				   sampler2D lightwarpSampler)
{
    vec3 vResult = vec3(0);
    vec3 ratio;
    
    lvec = lpoint.xyz - eyePos.xyz;
	float ldist = length(lvec);
	lvec = normalize(lvec);
	
	vResult = GetDiffuseTerm(lvec, eyeNormal.xyz, halfLambert, lightwarp, lightwarpSampler);
    
#ifdef BSP_LIGHTING
    bool hasHardFalloff = HasHardFalloff(falloff2);
    if (hasHardFalloff && !CheckHardFalloff(falloff2, ldist, vResult.x))
    {
        return vec3(0);
    }
    lattenv = GetFalloff(latten, falloff2, ldist);
    //if (hasHardFalloff)
    //{
    //    ApplyHardFalloff(lattenv, falloff2, ldist, vResult.x);
    //}
#else
    lattenv = 1.0 / (latten.x + latten.y*ldist + latten.z*ldist*ldist);
#endif
    
    ratio = vec3(lattenv, lattenv, lattenv);
	
    vResult *= lcolor.rgb * ratio;
	return vResult;
}

vec3 GetSpotlight(vec4 lpoint, vec4 latten, vec4 lcolor, inout float lattenv, inout vec3 lvec, vec4 ldir,
                  vec4 falloff2, vec4 falloff3,
                  vec4 eyePos, vec4 eyeNormal, bool halfLambert, bool lightwarp,
                  sampler2D lightwarpSampler)
{
    lvec = lpoint.xyz - eyePos.xyz;
    float ldist = length(lvec);
    lvec = normalize(lvec);
    vec3 vResult = GetDiffuseTerm(lvec, eyeNormal.xyz, halfLambert, lightwarp, lightwarpSampler); 
    
#ifdef BSP_LIGHTING
    
    bool hasHardFalloff = HasHardFalloff(falloff2);
    if (hasHardFalloff && !CheckHardFalloff(falloff2, ldist, vResult.x))
    {
        return vec3(0);
    }

    float dot2 = clamp(dot(lvec, normalize(-ldir.xyz)), 0, 1);
    if (dot2 <= falloff2.w)
    {
        // outside entire cone
        return vec3(0);
    }
    
    lattenv = GetFalloff(latten, falloff2, ldist);
    lattenv *= dot2;
    
    float mult = 1.0;
    
    if (dot2 <= latten.w)
    {
        mult *= (dot2 - falloff2.w) / (latten.w - falloff2.w);
        mult = clamp(mult, 0, 1);
    }
    
    float exp = falloff3.x;
    if (exp != 0.0 && exp != 1.0)
    {
        mult = pow(mult, exp);
    }
    
    lattenv *= mult;
    
    //if (hasHardFalloff)
    //{
    //    ApplyHardFalloff(lattenv, falloff2, ldist, vResult.x);
    //}
    
#else
    float langle = clamp(dot(ldir.xyz, lvec), 0, 1);
    lattenv = 1/(latten.x + latten.y*ldist + latten.z*ldist*ldist);
    lattenv *= pow(langle, latten.w);
    if (langle < ldir.w) return vec3(0);
#endif

    return (vResult * lcolor.rgb) * lattenv;
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

float Fresnel(vec3 vNormal, vec3 vEyeDir)
{
    float fresnel = 1 - clamp(dot(vNormal, normalize(vEyeDir)), 0, 1);
    return fresnel * fresnel;
}

float Fresnel4(vec3 vNormal, vec3 vEyeDir)
{
    float fresnel = 1 - clamp(dot(vNormal, normalize(vEyeDir)), 0, 1);
    fresnel = fresnel * fresnel;
    return fresnel * fresnel;
}

void RimTerm(inout vec3 totalRim, vec3 eyePos, vec4 eyeNormal, vec4 rimExponent, float rimWidth, float lattenv, vec4 worldNormal)
{
	vec3 rimEyePos = normalize(-eyePos.xyz);
	float rIntensity = pow(rimWidth - max(dot(rimEyePos, eyeNormal.xyz), 0.0), 0.7);
	rIntensity = max(0.0, rIntensity);
    rIntensity = smoothstep(0.6, 1.0, rIntensity);
	totalRim += vec3(rIntensity * rimExponent.xyz * Fresnel(eyeNormal.xyz, eyePos.xyz));
}

void RimTerm2(inout vec3 totalRim, vec3 eyeNormal, vec3 eyeVec, vec3 lightVec, vec4 rimColor, float rimWidth)
{
    float rim = 1.0 - rimWidth;
    float diff = rimWidth - clamp(dot(eyeNormal, -lightVec), 0, 1);
    diff = step(rim, diff) * diff;
    diff = smoothstep(0.7, 1.0, diff);
    diff *= Fresnel(eyeNormal, eyeVec);
    totalRim += step(rim, diff) * (diff - rim) / rim;
}

void GetSpecular(float lattenv, vec4 eyeNormal, vec4 eyePos,
				 vec3 specularTint, vec3 lightColor, float shininess, float boost, vec3 lightVec, vec3 eyeVec,
                 inout vec3 olspec)
{
    vec3 rim = vec3(0);
    
	vec3 lhalf = normalize(lightVec - normalize(eyePos.xyz));
    float LdotR = clamp(dot(eyeNormal.xyz, lhalf), 0, 1);

	//olspec += vec3(1.0);

    if (shininess > 0.0)
    {
        vec3 lspec = specularTint * lightColor;
        lspec *= pow(LdotR, shininess);
        lspec *= boost;
        // mask with N.L
        lspec *= dot(lightVec, eyeNormal.xyz);
        lspec *= lattenv;
        lspec *= Fresnel(eyeNormal.xyz, eyeVec);
        olspec += lspec;
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

vec3 CalcReflectionVectorUnnormalized(vec3 normal, vec3 eyeVector)
{
	return (2.0*(dot( normal, eyeVector ))*normal) - (dot( normal, normal )*eyeVector);
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
    
    tmp.xy = ooLen * tmp.xy + 1.0;
    
    return tmp.xy * 0.5;
}

vec4 SampleSphereMap(vec3 eyeVec, vec4 eyeNormal, mat4 invViewMatrix,
				   vec3 parallaxOffset, sampler2D sphereSampler)
{
	vec3 r = normalize(reflect(-eyeNormal.xyz, eyeVec));//CalcReflectionVectorNormalized(eyeNormal.xyz, eyeVec);
	vec2 coords = GetSphereMapTexCoords(r, invViewMatrix) - parallaxOffset.xy;
    
	return texture2D(sphereSampler, coords);
}

vec4 SampleCubeMap(vec3 worldCamToVert, vec4 worldNormal, mat4 invViewMatrix, vec3 parallaxOffset, samplerCube cubeSampler)
{
	//vec3 cmR = reflect(eyeNormal.xyz, eyeVec);
	vec3 cmR = CalcReflectionVectorUnnormalized(worldNormal.xyz, worldCamToVert);
	//cmR = vec3(invViewMatrix * vec4(cmR, 0.0));
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
