#version 330

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file unlitGeneric.frag.glsl
 * @author Brian Lach
 * @date December 30, 2018
 *
 */
 
#pragma include "phase_14/models/shaders/stdshaders/common_fog_frag.inc.glsl"

#ifdef BASETEXTURE
uniform sampler2D baseTextureSampler;
#endif

#ifdef COLOR_VERTEX
in vec4 l_color;
#elif defined(COLOR_FLAT)
uniform vec4 p3d_Color;
#endif

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

uniform vec4 p3d_ColorScale;

in vec2 l_texcoord;

out vec4 o_color;

void main()
{
    o_color = vec4(1.0);
    
#ifdef BASETEXTURE
    vec4 albedo = texture2D(baseTextureSampler, l_texcoord);
    o_color.rgb *= albedo.rgb;
    #ifdef TRANSLUCENT
	o_color.a *= albedo.a;
	#endif
#endif

#ifdef COLOR_VERTEX
	o_color *= l_color;
#elif defined(COLOR_FLAT)
	o_color *= p3d_Color;
#endif

    o_color *= p3d_ColorScale;

#ifdef ALPHA
    o_color.a *= ALPHA;
#endif

#ifdef FOG
	// Apply fog.
	o_color.rgb = GetFog(FOG, o_color, p3d_Fog.color, l_hPos, p3d_Fog.density,
						p3d_Fog.start, p3d_Fog.end, p3d_Fog.scale);
#endif

}
