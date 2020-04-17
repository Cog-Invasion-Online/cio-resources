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
 
#pragma include "shaders/stdshaders/common_fog_frag.inc.glsl"
#pragma include "shaders/stdshaders/common_frag.inc.glsl"
#pragma include "shaders/stdshaders/common_lighting_frag.inc.glsl"

#ifdef BASETEXTURE
uniform sampler2D baseTextureSampler;
#endif

in vec4 l_vertexColor;

in vec2 l_texcoord;

#ifdef FOG
in vec4 l_eyePosition;
#endif

uniform vec4 p3d_TexAlphaOnly;

out vec4 o_color;

#ifdef NEED_AUX_BLOOM
    layout(location = 3) out vec4 o_aux_bloom;
#endif

void main()
{
    o_color = vec4(1.0);
    
#ifdef BASETEXTURE
    vec4 albedo = SampleAlbedo(baseTextureSampler, l_texcoord);
    o_color.rgb *= albedo.rgb;
    #ifdef TRANSLUCENT
	o_color.a *= albedo.a;
	#endif
#endif

    o_color += p3d_TexAlphaOnly;

    o_color *= l_vertexColor;

#ifdef ALPHA
    o_color.a *= ALPHA;
#endif

#ifdef ALPHA_TEST
    if (!AlphaTest(o_color.a))
    {
        discard;
    }
#endif

#ifdef FOG
	ApplyFog(o_color, l_eyePosition);
#endif

	FinalOutput(o_color);
    
    #ifdef NEED_AUX_BLOOM
        #ifndef NO_BLOOM
            o_aux_bloom = o_color;
        #else
            o_aux_bloom = vec4(0, 0, 0, o_color.a);
        #endif
    #endif
}
