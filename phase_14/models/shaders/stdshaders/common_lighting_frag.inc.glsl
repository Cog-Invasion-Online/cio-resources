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
#pragma include "phase_14/models/shaders/stdshaders/common_brdf_frag.inc.glsl"

#define LIGHTTYPE_DIRECTIONAL	0
#define LIGHTTYPE_POINT			1
#define LIGHTTYPE_SPHERE		2
#define LIGHTTYPE_SPOT			3

#ifdef LIGHTWARP
    uniform sampler2D lightwarpSampler;
#endif

/**
 * Per-light parameters that are needed to
 * calculate the light's contribution.
 * 
 * V	:	camera->fragment (eye space)
 * N	:	fragment normal (eye space)
 * L	:	light->fragment (eye space)
 * H	:	light->fragment halfvector (eye space)
 */
struct LightingParams_t
{
    // All in eye-space
    
    // These are calculated once ahead of time
    // before calculating any lights
    vec4 fragPos;
    vec3 V; // camera->fragment
    vec3 N; // fragment normal
    float roughness;
    float metallic;
    vec3 specularColor;
    vec3 albedo;

    // This information is filled in for a light
    // before it gets calculated
    vec4 lDir;
    vec4 lPos;
    vec4 lColor;
    vec4 lAtten;
    vec4 falloff2;
    vec4 falloff3;
    float spotCosCutoff;
    float spotExponent;
    
    // These ones are calculated by the light
    vec3 L; // light->fragment ( or in case of directional light, direction of light )
    vec3 H; // half (light->fragment)
    float NdotL;
    float NdotV;
    float HdotN;
    float HdotV;
    float attenuation;
    float distance;
    
    // Sum of each light radiance,
    // filled in one-by-one.
    vec3 totalRadiance;
};

LightingParams_t newLightingParams_t(vec4 eyePos, vec3 eyeVec, vec3 eyeNormal,
                                     float roughness, float metallic, vec3 specular,
                                     vec3 albedo)
{
    LightingParams_t params = LightingParams_t(
        eyePos,
        eyeVec,
        eyeNormal,
        roughness,
        metallic,
        specular,
        albedo,
        
        vec4(0),
        vec4(0),
        vec4(0),
        vec4(0),
        vec4(0),
        vec4(0),
        0.0,
        0.0,
        
        vec3(0),
        vec3(0),
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        
        vec3(0)
    );
    
    return params;
}

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

void ComputeLightHAndDots(inout LightingParams_t params)
{
    params.H = normalize(params.V + params.L);
    
    params.NdotL = dot(params.N, params.L);
    #ifdef HALFLAMBERT
        params.NdotL = clamp(params.NdotL * 0.5 + 0.5, 0.0, 1.0);
        #ifndef LIGHTWARP
            params.NdotL *= params.NdotL;
        #endif
    #else // HALFLAMBERT
        params.NdotL = clamp(params.NdotL, 0.0, 1.0);
    #endif // HALFLAMBERT
    #ifdef LIGHTWARP
        params.NdotL = 2.0 * texture(lightwarpSampler, vec2(params.NdotL, 0.5)).r;
    #endif // LIGHTWARP
    
    params.NdotV = max(dot(params.N, params.V), 0.001);
    params.HdotN = max(dot(params.N, params.H), 0.001);
    params.HdotV = max(dot(params.H, params.V), 0.001);
}

void ComputeLightVectors_Dir(inout LightingParams_t params)
{
    params.L = normalize(params.lDir.xyz);
    
    ComputeLightHAndDots(params);
}

void ComputeLightVectors(inout LightingParams_t params)
{
    params.L = params.lPos.xyz - params.fragPos.xyz;
#ifndef BSP_LIGHTING
    params.L *= params.lPos.w;
#endif
    params.distance = length(params.L);
    params.L = normalize(params.L);
    
    ComputeLightHAndDots(params);
}

void AddTotalRadiance(inout LightingParams_t params)
{
    vec3 radiance = params.lColor.rgb * params.attenuation;
    
    float NDF 	= Distribution_GGX2(params.HdotN, params.roughness);
    float G 	= Geometry_Smith(params.NdotV,
			              params.NdotL,
				      params.roughness);
    vec3 F	= Fresnel_Schlick(params.specularColor, params.HdotV);
    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - params.metallic;
    
    vec3 numerator = NDF * G * F;
    float denominator = 4.0 * max(params.NdotV, 0.0) *
		        max(params.NdotL, 0.0);
    vec3 specular = numerator / max(denominator, 0.001);
    
    float NdotL = max(params.NdotL, 0.0);
    params.totalRadiance += (kD * params.albedo / PI + specular) * radiance * NdotL;
}

void GetPointLight(inout LightingParams_t params)
{
    
    ComputeLightVectors(params);
    
#ifdef BSP_LIGHTING
    bool hasHardFalloff = HasHardFalloff(params.falloff2);
    if (hasHardFalloff && !CheckHardFalloff(params.falloff2, params.distance, params.NdotL))
    {
        return;
    }
    params.attenuation = GetFalloff(params.lAtten, params.falloff2, params.distance);
#else
    params.attenuation = 1.0 / (params.lAtten.x + params.lAtten.y*params.distance + params.lAtten.z*params.distance*params.distance);
#endif

    AddTotalRadiance(params);
}

void GetSpotlight(inout LightingParams_t params)
{
    ComputeLightVectors(params);
    
#ifdef BSP_LIGHTING
    
    bool hasHardFalloff = HasHardFalloff(params.falloff2);
    if (hasHardFalloff && !CheckHardFalloff(params.falloff2, params.distance, params.NdotL))
    {
        return;
    }

    float dot2 = clamp(dot(params.L, normalize(-params.lDir.xyz)), 0, 1);
    if (dot2 <= params.falloff2.w)
    {
        // outside entire cone
        return;
    }
    
    params.attenuation = GetFalloff(params.lAtten, params.falloff2, params.distance);
    params.attenuation *= dot2;
    
    float mult = 1.0;
    
    if (dot2 <= params.lAtten.w)
    {
        mult *= (dot2 - params.falloff2.w) / (params.lAtten.w - params.falloff2.w);
        mult = clamp(mult, 0, 1);
    }
    
    float exp = params.falloff3.x;
    if (exp != 0.0 && exp != 1.0)
    {
        mult = pow(mult, exp);
    }
    
    params.attenuation *= mult;
    
    //if (hasHardFalloff)
    //{
    //    ApplyHardFalloff(lattenv, falloff2, ldist, vResult.x);
    //}
    
#else
    float langle = clamp(dot(params.lDir.xyz, -params.L), 0, 1);
    
    params.attenuation = 0.0;
    if (langle > params.spotCosCutoff)
    {
        params.attenuation = 1/(params.lAtten.x + params.lAtten.y*params.distance + params.lAtten.z*params.distance*params.distance);
        params.attenuation *= pow(langle, params.spotExponent);
    }
    else
    {
        return;
    }
#endif

    AddTotalRadiance(params);
}

void GetDirectionalLight(inout LightingParams_t params
                         #ifdef HAS_SHADOW_SUNLIGHT
                         , sampler2DArray shadowSampler, vec4 shadowCoords[PSSM_SPLITS]
                         #endif
                         )
{
	ComputeLightVectors_Dir(params);
    
    // Sunlight has constant full intensity
	params.attenuation = 1.0;
    
    #ifdef HAS_SHADOW_SUNLIGHT
        float lshad = 0.0;
        GetSunShadow(lshad, shadowSampler, shadowCoords, params.L, params.N);
        params.attenuation *= lshad;
    #endif
    
    AddTotalRadiance(params);
    
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

void DedicatedRimTerm(inout vec3 totalRim, vec3 worldNormal, vec3 worldEyeToVert,
                      vec3 ambientLight, float rimBoost, float rimExponent)
{
    // =================================================
    // Derived from Team Fortress 2's Illustrative Rendering paper
    // https://steamcdn-a.akamaihd.net/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf
    // =================================================
    
    vec3 up = vec3(0, 0, 1);
    totalRim += ( (ambientLight * rimBoost) * Fresnel(worldNormal, worldEyeToVert) *
                  max(0, dot(worldNormal, up)) );
}

void GetSpecular(float lattenv, vec4 eyeNormal, vec4 eyePos,
				 vec3 specularTint, vec3 lightColor, float shininess,
                 float boost, vec3 lightVec, vec3 eyeVec,
                 inout vec3 olspec)
{
	vec3 lhalf = normalize(lightVec - normalize(eyePos.xyz));
    float LdotR = clamp(dot(eyeNormal.xyz, lhalf), 0, 1);
    
    vec3 lspec = specularTint * lightColor;
    lspec *= pow(LdotR, shininess);
    lspec *= boost;
    // mask with N.L
    lspec *= dot(lightVec, eyeNormal.xyz);
    lspec *= lattenv;
    lspec *= Fresnel(eyeNormal.xyz, eyeVec);
    olspec += lspec;
}

vec3 GetTangentSpaceNormal(sampler2D bumpSampler, vec2 texcoord)
{
	
	vec3 nSample = texture2D(bumpSampler, texcoord).rgb;
	return normalize((nSample * 2.0) - 1.0);
}

void TangentToEye(inout vec3 eyeNormal, vec3 eyeTangent, vec3 eyeBinormal, vec3 tangentNormal)
{
	eyeNormal *= tangentNormal.z;
	eyeNormal += eyeTangent.xyz * tangentNormal.x;
	eyeNormal += eyeBinormal.xyz * tangentNormal.y;
	eyeNormal = normalize(eyeNormal.xyz);
}

void TangentToWorld(inout vec3 worldNormal, mat3 tangentSpaceTranspose, vec3 tangentNormal)
{
	worldNormal = tangentSpaceTranspose * tangentNormal;
}

void GetBumpedEyeNormal(inout vec4 finalEyeNormal, sampler2D bumpSampler, vec4 texcoord,
					 vec4 tangent, vec4 binormal)
{
	// Translate tangent-space normal in map to view-space.
	vec3 tsnormal = GetTangentSpaceNormal(bumpSampler, texcoord.xy);
	TangentToEye(finalEyeNormal.xyz, tangent.xyz, binormal.xyz, tsnormal);
}

void GetBumpedWorldNormal(inout vec4 finalWorldNormal, sampler2D bumpSampler, vec4 texcoord,
		          mat3 tangentSpaceTranspose)
{
	vec3 tsnormal = GetTangentSpaceNormal(bumpSampler, texcoord.xy);
	TangentToWorld(finalWorldNormal.xyz, tangentSpaceTranspose, tsnormal);
}

void GetBumpedEyeAndWorldNormal(inout vec4 finalEyeNormal, inout vec4 finalWorldNormal, sampler2D bumpSampler, vec4 texcoord,
				vec4 eyeTangent, vec4 eyeBinormal, mat3 tangentSpaceTranspose)
{
	vec3 tsnormal = GetTangentSpaceNormal(bumpSampler, texcoord.xy);
	TangentToEye(finalEyeNormal.xyz, eyeTangent.xyz, eyeBinormal.xyz, tsnormal);
	TangentToWorld(finalWorldNormal.xyz, tangentSpaceTranspose, tsnormal);
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

vec4 SampleCubeMap(vec3 worldCamToVert, vec4 worldNormal, vec3 parallaxOffset, samplerCube cubeSampler)
{
	vec3 cmR = CalcReflectionVectorUnnormalized(worldNormal.xyz, worldCamToVert);
	return texture(cubeSampler, cmR - parallaxOffset.xyz);
}

vec4 SampleCubeMapLod(vec3 worldCamToVert, vec4 worldNormal,
                      vec3 parallaxOffset, samplerCube cubeSampler,
                      float roughness)
{
	vec3 cmR = CalcReflectionVectorUnnormalized(worldNormal.xyz, worldCamToVert);
	return textureLod(cubeSampler, cmR - parallaxOffset.xyz,
                      roughness * 4.0);
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
