/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file water_f.glsl
 * @author Brian Lach
 * @date July 08, 2018
 *
 * @desc Pixel shader for the water effects.
 */

#version 430

#pragma include "phase_14/models/shaders/stdshaders/common_lighting_frag.inc.glsl"

in vec4 texcoord0;
in vec2 texcoord1;

in vec3 l_worldNormal;
in vec3 l_worldEyeToVert;
in mat3 l_tangentSpaceTranspose;

uniform float osg_FrameTime;

uniform sampler2D refl;
uniform sampler2D refr;
uniform sampler2D refr_depth;
uniform sampler2D dudv;
uniform sampler2D normal_map;

uniform float dudv_strength;
uniform vec2 move_factor;
uniform float near;
uniform float far;
uniform vec4 fog_color;
uniform vec4 water_tint;
uniform float fog_density;
uniform float reflect_factor;
uniform float static_depth;

out vec4 frag_color;

float calc_dist( float depth )
{
        return 2.0 * near * far / ( far + near - ( 2.0 * depth - 1.0 ) * ( far - near ) );
}

vec2 calc_distort( vec2 distort_coord )
{
        return ( texture( dudv, distort_coord ).rg * 2.0 - 1.0 ) * dudv_strength;
}

float calc_fog_factor( float distance, float density )
{
	return 1.0 - clamp( exp( -density * distance ), 0.0, 1.0 );
}

void main()
{
        float depth = textureProj( refr_depth, texcoord0 ).r;
        float floor_dist = calc_dist( depth );

		float fog_amt = calc_fog_factor( floor_dist, fog_density );
        
        depth = gl_FragCoord.z / gl_FragCoord.w;
        float water_dist = calc_dist( depth );
        float water_depth = floor_dist - water_dist;

		float movx = move_factor.x * osg_FrameTime;
		float movy = move_factor.y * osg_FrameTime;
        
        vec2 distort_coord1 = vec2( -texcoord1.x + movx, texcoord1.y + movy );
        vec2 distort_coord2 = vec2( texcoord1.x + movx, -texcoord1.y + movy );
        
        vec2 distort1 = calc_distort( distort_coord1 );
        vec2 distort2 = calc_distort( distort_coord2 );
        
        float depth_factor = clamp( water_depth / static_depth, 0.0, 1.0 );
        
        vec2 total_distort = ( distort1 + distort2 ) * depth_factor;
        
        vec4 distorted_coords = texcoord0 + vec4( total_distort.x, total_distort.y, 0, 0 );
        vec4 refl_col = textureProj( refl, distorted_coords );
        vec4 refr_col = textureProj( refr, distorted_coords );
		refr_col = mix( refr_col, fog_color, fog_amt );
        
        mat3 tangentSpaceTranspose = l_tangentSpaceTranspose;
        tangentSpaceTranspose[2] = l_worldNormal;
        vec4 worldNormal = vec4(0);
        GetBumpedWorldNormal(worldNormal, normal_map, vec4(texcoord1, 0, 0),
		          tangentSpaceTranspose);
        worldNormal.xyz = normalize(worldNormal.xyz);
        
        // Fresnel effect
        float refr_factor = Fresnel4(worldNormal.xyz, l_worldEyeToVert.xyz);
        
        frag_color = mix( refr_col, refl_col, (refr_factor * depth_factor) * reflect_factor);
        frag_color.rgb = mix( frag_color.rgb, water_tint.rgb, water_tint.a );
}
