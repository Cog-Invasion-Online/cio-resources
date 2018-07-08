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

in vec4 texcoord0;
in vec2 texcoord1;
in vec3 eye_vec;

uniform sampler2D refl;
uniform sampler2D refr;
uniform sampler2D refr_depth;
uniform sampler2D dudv;
uniform sampler2D normal_map;

uniform float reflectivity;
uniform float shine_damper;
uniform float dudv_strength;
uniform float move_factor;
uniform float near;
uniform float far;
uniform vec3 lightdir;
uniform vec3 lightcol;

float calc_dist( float depth )
{
        return 2.0 * near * far / ( far + near - ( 2.0 * depth - 1.0 ) * ( far - near ) );
}

vec2 calc_distort( vec2 distort_coord )
{
        return ( texture( dudv, distort_coord ).rg * 2.0 - 1.0 ) * dudv_strength;
}

void main()
{
        float depth = textureProj( refr_depth, texcoord0 ).r;
        float floor_dist = calc_dist( depth );
        
        depth = gl_FragCoord.z / gl_FragCoord.w;
        float water_dist = calc_dist( depth );
        float water_depth = floor_dist - water_dist;
        
        vec2 distort_coord1 = vec2( -texcoord1.x + move_factor, texcoord1.y + move_factor );
        vec2 distort_coord2 = vec2( texcoord1.x + move_factor, -texcoord1.y + move_factor );
        
        vec2 distort1 = calc_distort( distort_coord1 );
        vec2 distort2 = calc_distort( distort_coord2 );
        
        float depth_factor = clamp( water_depth / 30.0, 0.0001, 1.0 );
        
        vec2 total_distort = ( distort1 + distort2 ) * depth_factor;
        
        vec4 distorted_coords = texcoord0 + vec4(total_distort.x, total_distort.y, 0, 0);
        vec4 refl_col = textureProj( refl, distorted_coords );
        vec4 refr_col = textureProj( refr, distorted_coords );
        
        vec4 norm_col = texture( normal_map, texcoord1 + total_distort );
        vec3 normal = vec3( norm_col.r * 2.0 - 1.0, norm_col.b, norm_col.g * 2.0 - 1.0 );
        normal = normalize( normal );
        
        vec3 refl_light = reflect( normalize( lightdir ), normal );
        float spec = max( dot( refl_light, eye_vec ), 0.0 );
        spec = pow( spec, shine_damper );
        vec3 spec_highlight = lightcol * spec * reflectivity;
        
        // Fresnel effect
        float refr_factor = clamp( dot( eye_vec, vec3( 0, 0, 1 ) ), 0.3, 1.0 );
        
        gl_FragColor = mix( refl_col, refr_col, clamp( refr_factor / depth_factor, 0, 1 ) );
        gl_FragColor.rgb = mix( gl_FragColor.rgb, vec3( 0.0, 0.3, 0.7 ), 0.2 );
        gl_FragColor.rgb += spec_highlight;
}