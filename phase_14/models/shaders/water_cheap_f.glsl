/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file water_cheap_f.glsl
 * @author Brian Lach
 * @date March 22, 2019
 *
 * @desc Cheap water pixel shader.
 *       Gets specular from a cubemap, uses alpha channel for fresnel.
 */

#version 430

#pragma include "phase_14/models/shaders/stdshaders/common_lighting_frag.inc.glsl"

in vec2 l_texcoord;

in vec3 l_worldNormal;
in vec3 l_worldEyeToVert;
in mat3 l_tangentSpaceTranspose;

uniform sampler2D normal_map;
uniform samplerCube cube_map;
uniform float reflectivity;
uniform vec4 water_tint;

out vec4 frag_color;

void main()
{
        mat3 tangentSpaceTranspose = l_tangentSpaceTranspose;
        tangentSpaceTranspose[2] = l_worldNormal;
        vec4 worldNormal = vec4(0);
        GetBumpedWorldNormal(worldNormal, normal_map, vec4(l_texcoord, 0, 0),
		          tangentSpaceTranspose);
        worldNormal.xyz = normalize(worldNormal.xyz);
        
        vec3 specular = SampleCubeMap(l_worldEyeToVert, worldNormal, vec3(0), cube_map).rgb;
        float fresnel = max(Fresnel4(worldNormal.xyz, l_worldEyeToVert.xyz), 0.1);
        
        frag_color.rgb = water_tint.rgb + (specular * reflectivity);
        frag_color.a = fresnel * water_tint.a;
}
