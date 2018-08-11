/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file water_bottom_f.glsl
 * @author Brian Lach
 * @date July 08, 2018
 *
 * @desc Pixel shader for the water effects.
 */

#version 430

in vec4 texcoord0;
in vec2 texcoord1;

uniform sampler2D refr;
uniform sampler2D dudv;

uniform float dudv_strength;
uniform float move_factor;
uniform vec4 water_tint;

out vec4 frag_color;

vec2 calc_distort( vec2 distort_coord )
{
        return ( texture( dudv, distort_coord ).rg * 2.0 - 1.0 ) * dudv_strength;
}

void main()
{       
        vec2 distort_coord1 = vec2( -texcoord1.x + move_factor, texcoord1.y + move_factor );
        vec2 distort_coord2 = vec2( texcoord1.x + move_factor, -texcoord1.y + move_factor );
        
        vec2 distort1 = calc_distort( distort_coord1 );
        vec2 distort2 = calc_distort( distort_coord2 );
        
        vec2 total_distort = distort1 + distort2;
        
        vec4 distorted_coords = texcoord0 + vec4(total_distort.x, total_distort.y, 0, 0);
        vec4 refr_col = textureProj( refr, distorted_coords );
        
        frag_color = refr_col;
        frag_color.rgb = mix( frag_color.rgb, water_tint.rgb, water_tint.a );
}