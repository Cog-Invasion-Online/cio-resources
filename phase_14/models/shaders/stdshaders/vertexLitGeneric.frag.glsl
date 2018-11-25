#version 150

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file vertexLitGeneric.frag.glsl
 * @author Brian Lach
 * @date October 29, 2018
 *
 */

#pragma include "phase_14/models/shaders/stdshaders/common_lighting_frag.inc.glsl"
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

#ifdef NEED_WORLD_POSITION
in vec4 l_worldPosition;
#endif

#ifdef NEED_WORLD_NORMAL
in vec4 l_worldNormal;
#endif

#ifdef NEED_EYE_POSITION
in vec4 l_eyePosition;
#endif

#ifdef NEED_EYE_NORMAL
in vec4 l_eyeNormal;
#endif

in vec4 l_texcoord;

#ifdef ALBEDO
uniform sampler2D albedoSampler;
#else // ALBEDO
uniform sampler2D p3d_Texture0;
#define albedoSampler p3d_Texture0
#endif

#ifdef HEIGHTMAP
uniform sampler2D heightSampler;
#endif
#ifdef SPHEREMAP
uniform sampler2D sphereSampler;
uniform mat4 p3d_ViewMatrixInverse;
#endif
#ifdef CUBEMAP
uniform sampler2D cubeSampler;
#endif
#ifdef GLOWMAP
uniform sampler2D glowSampler;
#endif
#ifdef GLOSSMAP
uniform sampler2D glossSampler;
#endif

#ifdef NORMALMAP
uniform sampler2D normalSampler;
in vec4 l_tangent;
in vec4 l_binormal;
#endif

#if defined(HEIGHTMAP)
in vec3 l_eyeVec;
#endif

#if defined(HAVE_AUX_NORMAL) || defined(HAVE_AUX_GLOW)
out vec4 o_aux;
#endif

#ifdef NEED_COLOR
#ifdef COLOR_VERTEX
in vec4 l_color;
#elif defined(COLOR_FLAT)
uniform vec4 p3d_Color;
#endif
#endif

#if NUM_CLIP_PLANES > 0
uniform vec4 p3d_ClipPlane[NUM_CLIP_PLANES];
#endif

#ifdef HAS_MAT

uniform struct
{
#ifdef MAT_AMBIENT
	vec4 ambient;
#endif
    
#ifdef MAT_EMISSION
    vec4 emission;
#endif
    
//#ifdef MAT_DIFFUSE
    vec4 diffuse;
//#endif
    
#ifdef MAT_SPECULAR
    vec3 specular;
    float shininess;
#endif
    
#ifdef MAT_RIM
    vec4 rimColor;
    float rimWidth;
#endif
    
#ifdef MAT_LIGHTWARP
    sampler2D lightwarp;
#endif
   
} p3d_Material;

#endif

#ifdef LIGHTING

uniform int lightTypes[NUM_LIGHTS];

#ifdef BSP_LIGHTING
uniform int lightCount[1];
uniform mat4 lightData[NUM_LIGHTS];
//in vec4 l_lightPos[NUM_LIGHTS];
//in vec4 l_lightDir[NUM_LIGHTS];
#ifdef AMBIENT_CUBE
uniform vec3 ambientCube[6];
#endif
#else

uniform struct
{
    vec4 diffuse;
    vec4 position;
    vec3 attenuation;
} p3d_LightSource[NUM_LIGHTS];

uniform struct
{
    vec4 ambient;
} p3d_LightModel;

#endif

#ifdef HAS_SHADOW_SUNLIGHT
uniform sampler2DArray pssmSplitSampler;
in vec4 l_pssmCoords[PSSM_SPLITS];
#endif

#endif

uniform vec4 p3d_ColorScale;

out vec4 o_color;

void DoGetSpecAndRim(float lattenv, vec4 finalEyeNormal, vec4 l_eyePosition,
                     float shininess, vec3 lvec, inout vec3 spec, inout vec3 rim)
{
    
#if defined(HAVE_SPECULAR) || defined(MAT_RIM)
    GetSpecular(lattenv, finalEyeNormal, l_eyePosition,
    
#ifdef HAVE_SPECULAR
                p3d_Material.specular,
#else
                vec3(1.0),
#endif
                shininess, lvec, spec,

#ifdef MAT_RIM
                true, p3d_Material.rimWidth, p3d_Material.rimColor,
#else
                false, 0.0, vec4(0.0),
#endif
                rim);
         
#endif
}

void main()
{
	// Clipping first!
#if NUM_CLIP_PLANES > 0
	for (int i = 0; i < NUM_CLIP_PLANES; i++)
	{
		if (ClipPlaneTest(l_worldPosition, p3d_ClipPlane[i])) 
		{
			discard;
		}
	}
#endif

	vec4 result = vec4(0.0);
#if defined(HAVE_AUX_NORMAL) || defined(HAVE_AUX_GLOW)
	o_aux = vec4(0.0);
#endif

	vec3 parallaxOffset = vec3(0.0);

#ifdef HEIGHTMAP
	parallaxOffset = l_eyeVec.xyz * (texture2D(heightSampler, l_texcoord.xy).rgb * 2.0 - 1.0) * PARALLAX_MAPPING_SCALE;
	// Additional samples
	for (int i = 0; i < PARALLAX_MAPPING_SAMPLES; i++)
	{
		parallaxOffset += l_eyeVec.xyz * (parallaxOffset + (texture2D(heightSampler, l_texcoord.xy).rgb * 2.0 - 1.0)) * (0.5 * PARALLAX_MAPPING_SCALE);
	}
#endif

#ifdef NEED_EYE_NORMAL
	vec4 finalEyeNormal = l_eyeNormal;
#else
	vec4 finalEyeNormal = vec4(0.0);
#endif

#ifdef NORMALMAP
	GetBumpedNormal(finalEyeNormal, normalSampler, l_texcoord,
			        l_tangent, l_binormal);
#endif

#ifdef NEED_EYE_NORMAL
	finalEyeNormal.xyz = normalize(finalEyeNormal.xyz);
#endif

#ifdef HAVE_AUX_NORMAL
	o_aux.rgb = (finalEyeNormal.xyz * 0.5) + vec3(0.5, 0.5, 0.5);
#endif

    vec4 totalSpecular = vec4(0.0);
    vec4 totalRim = vec4(0.0);

#ifdef LIGHTING

	vec4 totalDiffuse = vec4(0.0);

//#ifdef HAVE_SPECULAR
	
#ifdef MAT_SPECULAR
	float shininess = p3d_Material.shininess;
#else
	float shininess = 50.0;
#endif
//#endif

#ifdef HAVE_SEPARATE_AMBIENT
	vec4 totalAmbient = vec4(0.0);
#ifdef BSP_LIGHTING
    totalAmbient.rgb += AmbientCubeLight(l_worldNormal.xyz, ambientCube);
#else
    totalAmbient += p3d_LightModel.ambient;
#endif
#else // HAVE_SEPARATE_AMBIENT
#ifdef BSP_LIGHTING
    totalDiffuse.rgb += AmbientCubeLight(l_worldNormal.xyz, ambientCube);
#else
    totalDiffuse += p3d_LightModel.ambient;
#endif
#endif

//#ifdef MAT_RIM
//	vec4 totalRim = vec4(0.0);
//	RimTerm(totalRim, l_eyePosition, finalEyeNormal, p3d_Material.rimColor, p3d_Material.rimWidth);
//#endif
    
    float ldist, lattenv, langle, lshad, lintensity;
	vec4 lcolor, lspec, lpoint, latten, ldir, leye;
	vec3 lvec, lhalf;

	// Now factor in local light sources
#ifdef BSP_LIGHTING
	for (int i = 0; i < lightCount[0]; i++)
#else
	for (int i = 0; i < NUM_LIGHTS; i++)
#endif
	{
#ifdef BSP_LIGHTING
		//lpoint = l_lightPos[i];
		//ldir = l_lightDir[i];
		lpoint = lightData[i][0];
		ldir = lightData[i][1];
		latten = lightData[i][2];
		lcolor = lightData[i][3];
#else
		lcolor = p3d_LightSource[i].diffuse;
		ldir = p3d_LightSource[i].position;
		lpoint = p3d_LightSource[i].position;
		latten = vec4(p3d_LightSource[i].attenuation, 0.0);
#endif
        
        lattenv = 0.0;
        lvec = vec3(0);

		if (lightTypes[i] == LIGHTTYPE_POINT)
		{
            
			totalDiffuse.rgb += GetPointLight(lpoint, latten, lcolor, lattenv, lvec,
                                          l_eyePosition, finalEyeNormal,

#ifdef MAT_HALFLAMBERT
				true,
#else
				false,
#endif

#ifdef MAT_LIGHTWARP
				true, p3d_Material.lightwarp
#else
				false, albedoSampler
#endif

			);

            DoGetSpecAndRim(lattenv, finalEyeNormal, l_eyePosition, shininess, lvec, totalSpecular.rgb, totalRim.rgb);

		}
        else if (lightTypes[i] == LIGHTTYPE_DIRECTIONAL)
        {
            totalDiffuse.rgb += GetDirectionalLight(ldir, lcolor, finalEyeNormal, lvec,
#ifdef MAT_HALFLAMBERT
                true,
#else
                false,
#endif
                
#ifdef MAT_LIGHTWARP
                true, p3d_Material.lightwarp
#else
                false, albedoSampler
#endif
                
#ifdef HAS_SHADOW_SUNLIGHT
                , true, pssmSplitSampler, l_pssmCoords
#endif
            );
            
            DoGetSpecAndRim(1.0, finalEyeNormal, l_eyePosition, shininess, -lvec, totalSpecular.rgb, totalRim.rgb);
        }
        else if (lightTypes[i] == LIGHTTYPE_SPOT)
        {
            totalDiffuse.rgb += GetSpotlight(lpoint, latten, lcolor, lattenv, lvec, ldir,
                                            l_eyePosition, finalEyeNormal,
#ifdef MAT_HALFLAMBERT
                true,
#else
                false,
#endif
            
#ifdef MAT_LIGHTWARP
                true, p3d_Material.lightwarp
#else
                false, albedoSampler
#endif
            
            );
            
            DoGetSpecAndRim(lattenv, finalEyeNormal, l_eyePosition, shininess, lvec, totalSpecular.rgb, totalRim.rgb);
        }
	}

#ifdef GLOWMAP
	vec4 glow = texture2D(glowSampler, l_texcoord.xy - parallaxOffset.xy);
#endif

	// Begin view-space light summation.
#ifdef MAT_EMISSION
#ifdef GLOWMAP
	result = p3d_Material.emission * clamp(2 * (glow.a - 0.5), 0, 1);
#else
	result = p3d_Material.emission;
#endif
#else // MAT_EMISSION
#ifdef GLOWMAP
	result = vec4(clamp(2 * (glow.a - 0.5), 0, 1));
#else
	result = vec4(0.0);
#endif
#endif

#ifdef HAVE_SEPARATE_AMBIENT
	result += totalAmbient;
#endif

#ifdef MAT_DIFFUSE
	result += totalDiffuse * p3d_Material.diffuse;
#else
	result += totalDiffuse;
#endif

//#ifdef MAT_RIM
	//result += totalRim;
//#endif

#ifdef COLOR_VERTEX
	result *= l_color;
#elif defined(COLOR_FLAT)
	result *= p3d_Color;
#endif

#ifndef HDR
	result = clamp(result, 0, 1);
#endif

#ifdef CALC_PRIMARY_ALPHA
#ifdef COLOR_VERTEX
	result.a = l_color.a;
#elif defined(COLOR_FLAT)
	result.a = p3d_Color.a;
#else
	result.a = 1.0;
#endif
#endif

#else // LIGHTING

#ifdef COLOR_VERTEX
	result = l_color;
#elif defined(COLOR_FLAT)
	result = p3d_Color;
#else
	result = vec4(1);
#endif

#endif // LIGHTING

	result *= p3d_ColorScale;

#ifdef ALBEDO
	result *= SampleAlbedo(l_texcoord, parallaxOffset, albedoSampler);
#endif

#ifdef SPHEREMAP
	result += SampleSphereMap(l_eyePosition.xyz, finalEyeNormal,
							  p3d_ViewMatrixInverse, parallaxOffset,
							  sphereSampler);
#endif

#ifdef CUBEMAP
	result += SampleCubeMap(l_eyeVec, finalEyeNormal, parallaxOffset, cubeSampler);
#endif

#ifdef ALPHA_TEST
	if (AlphaTest(result.a, ALPHA_TEST_REF))
	{
		discard;
	}
#endif

#ifdef HAVE_GLOW
#ifdef GLOWMAP
	result.a = glow.a;
#else
	result.a = 0.5;
#endif
#endif

#ifdef HAVE_AUX_GLOW
#ifdef GLOWMAP
	o_aux.a = glow.a;
#else
	o_aux.a = 0.5;
#endif
#endif

//#ifdef HAVE_SPECULAR
#ifdef MAT_SPECULAR
	totalSpecular.rgb *= p3d_Material.specular;
#endif
#ifdef GLOSSMAP
	totalSpecular *= texture2D(glossSampler, l_texcoord.xy - parallaxOffset.xy).a;
#endif
	result.rgb += max(totalSpecular.rgb, totalRim.rgb);
//#endif

#ifdef FOG
	// Apply fog.
	result.rgb = GetFog(FOG, result, p3d_Fog.color, l_hPos, p3d_Fog.density,
						p3d_Fog.start, p3d_Fog.end, p3d_Fog.scale);
#endif

	o_color = result * 1.0000001;
}
