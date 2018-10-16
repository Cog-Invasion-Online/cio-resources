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
//in vec2 texcoord2;
in vec3 eye_vec;
in vec3 eye_normal;
in vec3 world_normal;

uniform float osg_FrameTime;

uniform sampler2D refl;
uniform sampler2D refr;
uniform sampler2D refr_depth;
uniform sampler2D dudv;
uniform sampler2D normal_map;
uniform sampler2D env_map;

uniform float reflectivity;
uniform float shine_damper;
uniform float dudv_strength;
uniform vec2 move_factor;
uniform float near;
uniform float far;
uniform vec3 lightdir;
uniform vec3 lightcol;
uniform vec4 fog_color;
uniform vec4 water_tint;
uniform float fog_density;
uniform float reflect_factor;
uniform float static_depth;
out vec4 frag_color;
in vec3 l_tangent;
in vec3 l_binormal;

uniform struct p3d_LightSourceParameters
{
    vec4 color;
    vec4 position;
} light;

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
        //float water_fog_depth_value = refr_col.a;
		refr_col = mix( refr_col, fog_color, fog_amt );
        
        vec4 norm_col = texture( normal_map, texcoord1 + total_distort );
        vec3 tsnormal = vec3( norm_col.r * 2.0 - 1.0, norm_col.g * 2.0 - 1.0, norm_col.b * 2.0 - 1.0 );
        tsnormal.z += 1;
        vec3 tmp = norm_col.rgb * vec3(-2, -2, 2) + vec3(1, 1, -1);
        tsnormal = normalize(tsnormal * dot(tsnormal, tmp) - tmp * tsnormal.z);
        vec3 eye_normal_mod = eye_normal;
        eye_normal_mod *= tsnormal.z;
        eye_normal_mod += l_tangent * tsnormal.x;
        eye_normal_mod += l_binormal * tsnormal.y;
        eye_normal_mod = normalize( eye_normal_mod );
        
        vec3 refl_light = reflect( normalize( -light.position.xyz ), eye_normal_mod );
        float spec = clamp( dot( refl_light, eye_vec ), 0.0, 1.0 );
        spec = pow( spec, shine_damper );
        vec3 spec_highlight = light.color.rgb * spec * reflectivity;
        
        // Fresnel effect
        float refr_factor = clamp( dot( eye_vec, world_normal ), 0.0, 1.0 );
        refr_factor = pow(1.0 - refr_factor, 5);
        
        frag_color = mix( refr_col, refl_col, (refr_factor * depth_factor) * (reflect_factor));//clamp( (refr_factor / depth_factor) * reflect_factor, 0, 1 ) );
        frag_color.rgb = mix( frag_color.rgb, water_tint.rgb, water_tint.a );
        frag_color.rgb += spec_highlight;
        //frag_color.rgb += texture2D(env_map, texcoord2).rgb * refr_factor;
        frag_color.rgb = clamp(frag_color.rgb, 0.0, 1.0);
}