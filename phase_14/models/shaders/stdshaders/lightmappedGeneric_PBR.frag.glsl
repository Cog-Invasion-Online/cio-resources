#version 330

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file lightmappedGeneric_PBR.frag.glsl
 * @author Brian Lach
 * @date March 10, 2019
 *
 * @desc Shader for lightmapped geometry (brushes, displacements).
 *
 */
 
#pragma optionNV(unroll all)
 
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

const vec3 g_localBumpBasis[3] = vec3[](
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

#if defined(ENVMAP) || defined(HAS_SHADOW_SUNLIGHT)
    in vec4 l_worldNormal;
#endif

#ifdef ARME
    uniform sampler2D armeSampler;
#endif

#if defined(ENVMAP)

    uniform samplerCube envmapSampler;
    uniform vec3 envmapTint;
    
    uniform sampler2D brdfLUTSampler;

    #ifdef BUMPMAP
        in mat3 l_tangentSpaceTranspose;
    #endif
    in vec4 l_worldEyeToVert;
    
#endif

#ifdef HAS_SHADOW_SUNLIGHT
    uniform sampler2DArray pssmSplitSampler;
    in vec4 l_pssmCoords[PSSM_SPLITS];
    uniform vec3 sunVector[1];
    uniform vec3 ambientLightIdentifier;
    uniform vec3 ambientLightMin;
    uniform vec2 ambientLightScale;
#endif

#ifdef BUMPMAP
    uniform sampler2D bumpSampler;
    in vec4 l_texcoordBumpMap;
    in vec4 l_tangent;
    in vec4 l_binormal;
#endif

#if defined(BUMPMAP) || defined(BUMPED_LIGHTMAP)
    in vec3 l_normal;
#endif

#if NUM_CLIP_PLANES > 0
    uniform vec4 p3d_ClipPlane[NUM_CLIP_PLANES];
    in vec4 l_eyePosition;
#endif

out vec4 outputColor;

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
    
    outputColor = vec4(0, 0, 0, 1);

    #ifdef BUMPMAP
        vec3 tangentSpaceNormal = GetTangentSpaceNormal(bumpSampler, l_texcoordBumpMap.xy);
    #endif
    
    #if defined(ENVMAP) || defined(HAS_SHADOW_SUNLIGHT)
        vec4 finalWorldNormal = l_worldNormal;
    #endif

    #ifdef ENVMAP
        #ifdef BUMPMAP
            mat3 tangentSpaceTranspose = l_tangentSpaceTranspose;
            tangentSpaceTranspose[2] = finalWorldNormal.xyz;
            TangentToWorld(finalWorldNormal.xyz, tangentSpaceTranspose, tangentSpaceNormal);
        #endif
    #endif
    
    #ifdef ARME
        vec4 armeParams = texture(armeSampler, l_texcoordBaseTexture.xy);
    #else
        vec4 armeParams = vec4(AO, ROUGHNESS, METALLIC, EMISSIVE);
    #endif
    
    float ao        = armeParams.x;
    float roughness = armeParams.y;
    float metallic  = armeParams.z;
    float emissive  = armeParams.w;
  
    #if defined(BUMPMAP) && defined(BUMPED_LIGHTMAP)
        // the normal for bumped lightmaps is in tangent space, not eye space
        vec3 msNormal = normalize(tangentSpaceNormal);
    #elif defined(BUMPED_LIGHTMAP)
        // hmm, there is a bumped lightmap but no normal map.
        vec3 msNormal = l_normal;
    #endif
    
    // Diffuse term.
    vec3 diffuseLighting = vec3(0);
    
    #if defined(FLAT_LIGHTMAP)
        
        diffuseLighting += LightmapSample(lightmapSampler, l_texcoordLightmap.xy, 0);
        
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
        
        diffuseLighting += finalLightmap;
        
    #endif
    
    #ifdef HAS_SHADOW_SUNLIGHT
        DoBlendShadow(diffuseLighting, pssmSplitSampler, l_pssmCoords,
                      ambientLightIdentifier, ambientLightMin, ambientLightScale.x);
    #endif
    
    // Ambient term.
    vec3 ambientLighting = vec3(1.0);
    #ifdef BASETEXTURE
        vec4 albedo = texture2D(baseTextureSampler, l_texcoordBaseTexture.xy);
    #else
        vec4 albedo = vec4(0.5, 0.5, 0.5, 1.0);
    #endif
    ambientLighting *= albedo.rgb;
    ambientLighting *= ao;
    
    // Specular term.
    vec3 specularLighting = vec3(0.0);
    vec3 specularColor = mix(vec3(0.04), albedo.rgb, metallic);
    #ifdef ENVMAP
        float NdotV = clamp(dot(finalWorldNormal.xyz, normalize(l_worldEyeToVert.xyz)), 0, 1);
        vec3 F = Fresnel_Schlick(specularColor, NdotV);
        
        vec3 spec = SampleCubeMapLod(l_worldEyeToVert.xyz,
                                     finalWorldNormal, vec3(0),
                                     envmapSampler, roughness).rgb;
        
        vec2 brdf = texture2D(brdfLUTSampler, vec2(NdotV, roughness)).xy;
        vec3 iblspec = spec * (F * brdf.x + brdf.y);
        specularLighting += iblspec;     
    #endif
    
    outputColor.rgb = (ambientLighting * diffuseLighting) + specularLighting;

    #ifdef FOG
        // Apply fog.
        outputColor.rgb = GetFog(FOG, outputColor, p3d_Fog.color, l_hPos, p3d_Fog.density,
                            p3d_Fog.start, p3d_Fog.end, p3d_Fog.scale);
    #endif

    #ifndef HDR
        outputColor.rgb = clamp(outputColor.rgb, 0.0, 1.0);
    #endif
    
    #ifdef TRANSLUCENT
        outputColor.a *= albedo.a;
    #endif
}
