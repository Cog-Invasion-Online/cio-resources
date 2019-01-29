#version 330

#extension GL_ARB_explicit_attrib_location : enable

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file vertexLitGeneric.frag.glsl
 * @author Brian Lach
 * @date October 29, 2018
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
 * - $selfillum (glowing parts of model)
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

#ifdef LIGHTWARP
    uniform sampler2D lightwarpSampler;
#endif

#ifdef ENVMAP
    uniform samplerCube envmapSampler;
    uniform vec3 envmapTint;
    uniform vec3 envmapContrast;
    uniform vec3 envmapSaturation;

    #ifdef ENVMAP_MASK
        uniform sampler2D envmapMaskSampler;
    #endif
#endif

#ifdef NEED_WORLD_VEC
    in vec4 l_worldEyeToVert;
#endif

#ifdef PHONG
    uniform vec2 phongBoost;
    uniform vec3 phongFresnelRanges;
    uniform vec3 phongTint;

    #ifdef PHONG_MASK
        uniform sampler2D phongMaskSampler;
    #endif

    #ifdef PHONG_EXP_TEX
        uniform sampler2D phongExponentTexture;
    #else // PHONG_EXP_TEX
        uniform vec2 phongExponent;
    #endif // PHONG_EXP_TEX

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
    uniform int lightTypes[NUM_LIGHTS];

    #ifdef BSP_LIGHTING

        uniform int lightCount[1];
        uniform mat4 lightData[NUM_LIGHTS];
        uniform mat4 lightData2[NUM_LIGHTS];
        #ifdef AMBIENT_CUBE
            uniform vec3 ambientCube[6];
        #endif

    #else // BSP_LIGHTING

        uniform struct
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

void DoGetSpecular(float lattenv, vec4 finalEyeNormal, vec4 l_eyePosition,
                   float exponent, vec3 tint, vec3 lvec, inout vec3 spec,
                   vec4 lightColor, vec4 albedoColor)
{
    #if defined(PHONG)
        GetSpecular(lattenv, finalEyeNormal, l_eyePosition,
                    tint, lightColor.xyz,
                    exponent, phongBoost.x, lvec, l_eyeDir, spec);
         
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
    #else
        vec4 finalWorldNormal = vec4(0.0);
    #endif

    #ifdef BUMPMAP
        #ifdef NEED_WORLD_NORMAL
            GetBumpedEyeAndWorldNormal(finalEyeNormal, finalWorldNormal, bumpSampler,
                l_texcoord, l_tangent, l_binormal, l_tangentSpaceTranspose);
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
        vec4 albedo = vec4(1.0);
    #endif

    #ifdef PHONG
        #ifdef PHONG_EXP_TEX
            float finalPhongExp = texture2D(phongExponentTexture, l_texcoord.xy).r;
        #else // PHONG_EXP_TEX
            float finalPhongExp = phongExponent.x;
        #endif

        vec3 finalPhongTint = phongTint;
        
        #ifdef PHONG_ALBEDO_TINT
            finalPhongTint *= albedo.rgb;
        #endif
        
        #ifdef PHONG_MASK
            finalPhongTint *= texture2D(phongMaskSampler, l_texcoord.xy).rgb;
        #endif
    #else // PHONG
        float finalPhongExp = 0.0;
        vec3 finalPhongTint = vec3(0);
    #endif // PHONG

    #ifdef LIGHTING

        vec4 totalDiffuse = vec4(0.0);
        vec4 totalAmbient = vec4(0.0);
        vec4 totalSpecular = vec4(0.0);
        vec4 totalRim = vec4(0.0);
        
        #ifdef BSP_LIGHTING
            totalAmbient.rgb += AmbientCubeLight(finalWorldNormal.xyz, ambientCube);
        #else
            totalAmbient += p3d_LightModel.ambient;
        #endif
        
        #ifdef RIMLIGHT
            // Dedicated rim lighting for this pixel,
            // adds onto final lighting, uses ambient light as basis
            DedicatedRimTerm(totalRim.rgb, l_worldNormal.xyz,
                             l_worldEyeToVert.xyz, totalAmbient.rgb,
                             rimlightParams.x, rimlightParams.y);
        #endif
        
        float ldist, lattenv, langle, lshad, lintensity;
        vec4 lcolor, lspec, lpoint, latten, ldir, leye, lfalloff2, lfalloff3;
        vec3 lvec, lhalf;
        int lightType;

        // Now factor in local light sources
        #ifdef BSP_LIGHTING
            for (int i = 0; i < lightCount[0]; i++)
        #else
            for (int i = 0; i < NUM_LIGHTS; i++)
        #endif
        {
            #ifdef BSP_LIGHTING
                lpoint = lightData[i][0];
                ldir = lightData[i][1];
                latten = lightData[i][2];
                lcolor = lightData[i][3];
                lfalloff2 = lightData2[i][0];
                lfalloff3 = lightData2[i][1];
            #else
                lcolor = p3d_LightSource[i].diffuse;
                ldir = p3d_LightSource[i].position;
                lpoint = p3d_LightSource[i].position;
                latten = vec4(p3d_LightSource[i].attenuation, 0.0);
                lfalloff2 = vec4(0);
                lfalloff3 = vec4(0);
            #endif // BSP_LIGHTING
            
            lattenv = 0.0;
            lshad = 0.0;
            lvec = vec3(0);
            
            lightType = lightTypes[i];

            if (lightType == LIGHTTYPE_POINT)
            {
                
                totalDiffuse.rgb += GetPointLight(lpoint, latten, lcolor, lattenv,
                                                  lvec, lfalloff2, lfalloff3,
                                                  l_eyePosition, finalEyeNormal,

                                                  #ifdef HALFLAMBERT
                                                      true,
                                                  #else
                                                      false,
                                                  #endif // HALFLAMBERT

                                                  #ifdef LIGHTWARP
                                                     true, lightwarpSampler
                                                  #else
                                                     false, baseTextureSampler
                                                  #endif // LIGHTWARP
                );
                
                // Determine specular (phong highlight) for this pixel from this light.
                DoGetSpecular(lattenv, finalEyeNormal, l_eyePosition, finalPhongExp,
                              finalPhongTint, lvec, totalSpecular.rgb, lcolor, albedo);

            }
            else if (lightType == LIGHTTYPE_DIRECTIONAL)
            {
                totalDiffuse.rgb += GetDirectionalLight(ldir, lcolor, finalEyeNormal, lvec,
                                                #ifdef HALFLAMBERT
                                                    true,
                                                #else
                                                    false,
                                                #endif // HALFLAMBERT
                    
                                                #ifdef LIGHTWARP
                                                    true, lightwarpSampler
                                                #else
                                                    false, baseTextureSampler
                                                #endif // LIGHTWARP
                    
                                                #ifdef HAS_SHADOW_SUNLIGHT
                                                    , true, pssmSplitSampler, l_pssmCoords, lshad
                                                #endif // HAS_SHADOW_SUNLIGHT
                );
                
                // use the shadow value as the falloff.
                // we shouldn't see any specular if the pixel is in shadow,
                // and the sun doesn't actually have a real falloff.
                DoGetSpecular(lshad, finalEyeNormal, l_eyePosition, finalPhongExp,
                              finalPhongTint, ldir.xyz, totalSpecular.rgb,
                              lcolor, albedo);
            }
            else if (lightType == LIGHTTYPE_SPOT)
            {
                #ifndef BSP_LIGHTING
                    ldir = vec4(p3d_LightSource[i].spotDirection, 0);
                #endif
                
                totalDiffuse.rgb += GetSpotlight(lpoint, latten, lcolor, lattenv, lvec, ldir, lfalloff2, lfalloff3,
                                                l_eyePosition, finalEyeNormal,
                                                #ifdef HALFLAMBERT
                                                    true,
                                                #else
                                                    false,
                                                #endif // HALFLAMBERT
                
                                                #ifdef LIGHTWARP
                                                    true, lightwarpSampler
                                                #else
                                                    false, baseTextureSampler
                                                #endif // HALFLAMBERT
                                                
                                                #ifndef BSP_LIGHTING
                                                    , p3d_LightSource[i].spotExponent,
                                                    p3d_LightSource[i].spotCosCutoff
                                                #endif
                );
                
                DoGetSpecular(lattenv, finalEyeNormal, l_eyePosition, finalPhongExp,
                              finalPhongTint, lvec, totalSpecular.rgb, lcolor, albedo);
            }
        }
        
        #if defined(BSP_LIGHTING) && defined(HAS_SHADOW_SUNLIGHT)
            // This is cascaded shadows from a fake light source in interior lighting or BSP levels
            DoBlendShadow(totalDiffuse.rgb, pssmSplitSampler, l_pssmCoords, sunVector[0], finalWorldNormal.xyz,
                          ambientLightIdentifier, ambientLightMin, ambientLightScale.x);
        #endif
        
        // ====================================
        // Light summation

        vec3 totalLight = totalAmbient.rgb + totalDiffuse.rgb;
        #ifndef HDR
            totalLight = clamp(totalLight, 0, 1);
        #endif
        
        vec4 result = vec4(totalLight.rgb, 1.0);
        
        // ======================================
        
    #else // LIGHTING
    
        // No lighting, pixel starts fullbright.
        vec4 result = vec4(1.0);
        
    #endif // LIGHTING
    
    // Modulate with albedo
    #ifdef BASETEXTURE
        result.rgb *= albedo.rgb;
        
        #ifdef TRANSLUCENT
            result.a *= albedo.a;
        #endif
    #endif
    
    // Modulate with vertex/flat colors
    #ifdef COLOR_VERTEX
        result *= l_color;
    #elif defined(COLOR_FLAT)
        result *= p3d_Color;
    #endif

	result *= p3d_ColorScale;
    
    #ifdef LIGHTING
        vec3 totalRimSpec = totalSpecular.rgb + totalRim.rgb;
        #ifndef HDR
            totalRimSpec = clamp(totalRimSpec, 0, 1);
        #endif
        result.rgb += totalRimSpec;
    #endif

    #ifdef ENVMAP

        vec3 spec = SampleCubeMap(l_worldEyeToVert.xyz, finalWorldNormal, vec3(0), envmapSampler).rgb;
        
        #ifdef ENVMAP_MASK
            spec *= texture2D(envmapMaskSampler, l_texcoord.xy).rgb;
        #endif
        
        spec *= envmapTint;
        
        // saturation and contrast
        //vec3 specSqr = spec * spec;
        //spec = mix(spec, specSqr, envmapContrast);
        //vec3 greyScale = vec3(dot(spec, vec3(.299, .587, .114)));
        //spec = mix(greyScale, spec, envmapSaturation);
        
        // calc fresnel factor
        spec *= Fresnel(l_worldNormal.xyz, normalize(l_worldEyeToVert.xyz));
        
        result.rgb += spec;
	
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
        result = clamp(result, 0, 1);
    #endif

    // Done!
	o_color = result;
}
