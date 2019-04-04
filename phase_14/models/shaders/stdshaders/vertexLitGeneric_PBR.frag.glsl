#version 330

#extension GL_ARB_explicit_attrib_location : enable

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file vertexLitGeneric_PBR.frag.glsl
 * @author Brian Lach
 * @date March 09, 2019
 * 
 * This is our big boy shader -- used for most models,
 * in particular ones that should be dynamically lit by light sources.
 * 
 * Supports a plethora of material effects:
 * - $basetexture
 * - $bumpmap
 * - $envmap
 * - $phong
 * - $rimlight
 * - $halflambert
 * - $lightwarp
 * - $alpha/$translucent
 * - $selfillum
 * 
 * And these render effects:
 * - Clip planes
 * - Flat colors
 * - Vertex colors
 * - Color scale
 * - Fog
 * - Lighting
 * - Cascaded shadow maps for directional lights
 * - Alpha testing
 * - Output normals/glow to auxiliary buffer
 * 
 * Will eventually support:
 * - $detail (finer detail at close distance)
 * - $displacement (parallax mapping)
 *
 */
 
#pragma optionNV(unroll all)

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
    in mat3 l_tangentSpaceTranspose;
#endif

#ifdef NEED_EYE_POSITION
    in vec4 l_eyePosition;
#endif

#ifdef NEED_EYE_NORMAL
    in vec4 l_eyeNormal;
#endif

in vec4 l_texcoord;

#ifdef BASETEXTURE
    uniform sampler2D baseTextureSampler;
#else // BASETEXTURE
    uniform sampler2D p3d_Texture0;
    #define baseTextureSampler p3d_Texture0
#endif

#ifdef ENVMAP
    uniform sampler2D brdfLUTSampler;
    uniform samplerCube envmapSampler;
    uniform vec3 envmapTint;
#endif

#ifdef ARME
    // =========================
    // AO/Roughness/Metallic/Emissive texture
    // =========================
    uniform sampler2D armeSampler;
#endif

#ifdef SELFILLUM
    uniform vec3 selfillumTint;
#endif

#ifdef NEED_WORLD_VEC
    in vec4 l_worldEyeToVert;
#endif

#ifdef RIMLIGHT
    uniform vec2 rimlightParams;
#endif

#ifdef BUMPMAP
    uniform sampler2D bumpSampler;
#endif

#ifdef NEED_TBN
    in vec4 l_tangent;
    in vec4 l_binormal;
#endif

#if NEED_EYE_VEC
    in vec3 l_eyeVec;
    in vec3 l_eyeDir;
#endif

#if defined(HAVE_AUX_NORMAL) || defined(HAVE_AUX_GLOW)
    layout(location = 1) out vec4 o_aux;
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

#ifdef LIGHTING

    #ifdef BSP_LIGHTING
    
        uniform int lightTypes[NUM_LIGHTS];
        uniform int lightCount[1];
        uniform mat4 lightData[NUM_LIGHTS];
        uniform mat4 lightData2[NUM_LIGHTS];
        #ifdef AMBIENT_CUBE
            uniform vec3 ambientCube[6];
        #endif

    #else // BSP_LIGHTING

        uniform struct p3d_LightSourceParameters
        {
            vec4 diffuse;
            vec4 position;
            vec3 attenuation;
            
            // Spotlights only
            float spotCosCutoff;
            float spotExponent;
            vec3 spotDirection;
        } p3d_LightSource[NUM_LIGHTS];

        uniform struct
        {
            vec4 ambient;
        } p3d_LightModel;

    #endif // BSP_LIGHTING

    #ifdef HAS_SHADOW_SUNLIGHT
        uniform sampler2DArray pssmSplitSampler;
        in vec4 l_pssmCoords[PSSM_SPLITS];
        uniform vec3 sunVector[1];
        uniform vec3 ambientLightIdentifier;
        uniform vec3 ambientLightMin;
        uniform vec2 ambientLightScale;
    #endif

#endif // LIGHTING

uniform vec4 p3d_ColorScale;

layout(location = 0) out vec4 o_color;

void main()
{
    // Clipping first!
    #if NUM_CLIP_PLANES > 0
        for (int i = 0; i < NUM_CLIP_PLANES; i++)
        {
            if (!ClipPlaneTest(l_eyePosition, p3d_ClipPlane[i])) 
            {
                // pixel outside of clip plane interiors
                discard;
            }
        }
    #endif
    
    #if defined(HAVE_AUX_NORMAL) || defined(HAVE_AUX_GLOW)
        o_aux = vec4(1.0);
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
	
    #ifdef NEED_WORLD_NORMAL
        vec4 finalWorldNormal = l_worldNormal;
        mat3 tangentSpaceTranspose = l_tangentSpaceTranspose;
        tangentSpaceTranspose[2] = finalWorldNormal.xyz;
    #else
        vec4 finalWorldNormal = vec4(0.0);
    #endif

    #ifdef BUMPMAP
        #ifdef NEED_WORLD_NORMAL
            GetBumpedEyeAndWorldNormal(finalEyeNormal, finalWorldNormal, bumpSampler,
                l_texcoord, l_tangent, l_binormal, tangentSpaceTranspose);
        #else
            GetBumpedEyeNormal(finalEyeNormal, bumpSampler, l_texcoord,
                            l_tangent, l_binormal);
        #endif
    #endif

    #ifdef HAVE_AUX_NORMAL
        o_aux.rgb = (finalEyeNormal.xyz * 0.5) + vec3(0.5, 0.5, 0.5);
    #endif

    #ifdef BASETEXTURE
        vec4 albedo = SampleAlbedo(l_texcoord, parallaxOffset, baseTextureSampler);
    #else
        vec4 albedo = vec4(0.0, 0.0, 0.0, 1.0);
    #endif
    // Modulate albedo with vertex/flat colors
    #ifdef COLOR_VERTEX
        albedo *= l_color;
    #elif defined(COLOR_FLAT)
        albedo *= p3d_Color;
    #endif
	albedo *= p3d_ColorScale;
    
    // AO/Roughness/Metallic/Emissive properties
    #ifdef ARME
        vec4 armeParams = texture(armeSampler, l_texcoord.xy);
    #else
        vec4 armeParams = vec4(AO, ROUGHNESS, METALLIC, EMISSIVE);
    #endif
    
    vec3 specularColor = mix(vec3(0.04), albedo.rgb, armeParams.z);

    #ifdef LIGHTING
    
        // Initialize our lighting parameters
        LightingParams_t params = newLightingParams_t(
            l_eyePosition,
            l_eyeVec,
            finalEyeNormal.xyz,
            armeParams.y,
            armeParams.z,
            specularColor,
            albedo.rgb
            #ifdef LIGHTWARP
                //, lightwarpSampler
            #endif
            );
            
        
        vec4 totalSpecular = vec4(0.0);
        vec3 totalRim = vec3(0.0);
        
        vec4 totalAmbient = vec4(0, 0, 0, 1);
        #ifdef BSP_LIGHTING
            totalAmbient.rgb += AmbientCubeLight(finalWorldNormal.xyz, ambientCube);
        #else
            totalAmbient.rgb += p3d_LightModel.ambient.rgb;
        #endif
        
        #ifdef RIMLIGHT
            // Dedicated rim lighting for this pixel,
            // adds onto final lighting, uses ambient light as basis
            DedicatedRimTerm(totalRim, l_worldNormal.xyz,
                             l_worldEyeToVert.xyz, totalAmbient.rgb,
                             rimlightParams.x, rimlightParams.y);
        #endif
        
        // Now factor in local light sources
        #ifdef BSP_LIGHTING
            int lightType;
            for (int i = 0; i < lightCount[0]; i++)
        #else
            for (int i = 0; i < NUM_LIGHTS; i++)
        #endif
        {
            #ifdef BSP_LIGHTING
                params.lPos = lightData[i][0];
                params.lDir = lightData[i][1];
                params.lAtten = lightData[i][2];
                params.lColor = lightData[i][3];
                params.falloff2 = lightData2[i][0];
                params.falloff3 = lightData2[i][1];
                lightType = lightTypes[i];
            #else
                params.lColor = p3d_LightSource[i].diffuse;
                params.lDir = p3d_LightSource[i].position;
                params.lPos = p3d_LightSource[i].position;
                params.lAtten = vec4(p3d_LightSource[i].attenuation, 0.0);
                params.falloff2 = vec4(0);
                params.falloff3 = vec4(0);
                bool isDirectional = params.lPos[3] == 0.0;
            #endif // BSP_LIGHTING
            
            #ifdef BSP_LIGHTING
                if (lightType == LIGHTTYPE_DIRECTIONAL)
            #else
                if (isDirectional)
            #endif
            {
                GetDirectionalLight(params
                                    #ifdef HAS_SHADOW_SUNLIGHT
                                        , pssmSplitSampler, l_pssmCoords
                                    #endif // HAS_SHADOW_SUNLIGHT
                );
            }
            #ifdef BSP_LIGHTING
                else if (lightType == LIGHTTYPE_POINT)
            #else
                else if (p3d_LightSource[i].spotExponent == 0.0)
            #endif
            {
                GetPointLight(params);
            }
            #ifdef BSP_LIGHTING
                else if (lightType == LIGHTTYPE_SPOT)
            #else
                else
            #endif
            {
                #ifndef BSP_LIGHTING
                    params.lDir = vec4(p3d_LightSource[i].spotDirection, 0);
                    params.spotCosCutoff = p3d_LightSource[i].spotCosCutoff;
                    params.spotExponent = p3d_LightSource[i].spotExponent;
                #endif
                
                GetSpotlight(params);
            }
        }
        
        vec3 totalRadiance = params.totalRadiance;
        
    #else // LIGHTING
    
        // No lighting, pixel starts fullbright.
        vec4 totalAmbient = vec4(1.0);
        vec3 totalRadiance = vec3(0);
        
    #endif // LIGHTING
    
    // Modulate with albedo  
    totalAmbient.rgb *= albedo.rgb;
    // Modulate with AO
    totalAmbient.rgb *= armeParams.x;
    
    vec4 color = totalAmbient + vec4(totalRadiance, 0.0);
    
    #ifdef SELFILLUM
        float selfillumMask = armeParams.w;
        color.rgb = mix(color.rgb, selfillumTint * albedo.rgb, selfillumMask);
    #endif
    
    vec3 specularLighting = vec3(0);
    
    #ifdef LIGHTING
        vec3 totalRimSpec = totalSpecular.rgb + totalRim.rgb;
        #ifndef HDR
            totalRimSpec = clamp(totalRimSpec, 0, 1);
        #endif
        specularLighting += totalRimSpec;
    #endif
    
    #ifdef ENVMAP
        
        float NdotV = clamp(dot(finalWorldNormal.xyz, normalize(l_worldEyeToVert.xyz)), 0, 1);
        vec3 F = Fresnel_Schlick(specularColor, NdotV);
        vec3 spec = SampleCubeMapLod(l_worldEyeToVert.xyz,
                                     finalWorldNormal, vec3(0),
                                     envmapSampler, armeParams.y).rgb;
        
        vec2 brdf = texture2D(brdfLUTSampler, vec2(NdotV, armeParams.y)).xy;
        vec3 iblspec = spec * (F * brdf.x + brdf.y);
        specularLighting += iblspec;
	
    #endif
    
    vec4 result = color + vec4(specularLighting.rgb, 0.0);
    result.a = 1.0;
    
    #ifdef TRANSLUCENT
        result.a *= albedo.a;
    #endif
    // Explicit alpha value from material.
    #ifdef ALPHA
        result.a *= ALPHA;
    #endif

    #ifdef ALPHA_TEST
        if (AlphaTest(ALPHA_TEST, result.a, ALPHA_TEST_REF))
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

    #ifdef FOG
        // Apply fog.
        result.rgb = GetFog(FOG, result, p3d_Fog.color, l_hPos, p3d_Fog.density,
                            p3d_Fog.start, p3d_Fog.end, p3d_Fog.scale);
    #endif
    
    #ifndef HDR
        result.rgb = clamp(result.rgb, 0, 1);
    #endif

    // Done!
	o_color = result;
}
