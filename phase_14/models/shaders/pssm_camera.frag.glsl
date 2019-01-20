#version 330

out vec4 o_color;

#ifdef BASETEXTURE
    uniform sampler2D baseTextureSampler;
#endif

in vec2 l_uv;

void main()
{
    #ifdef BASETEXTURE
	vec4 albedo = texture2D(baseTextureSampler, l_uv);
	#ifdef TRANSLUCENT
		float alpha = albedo.a;
	#elif defined(ALPHA)
		float alpha = float(ALPHA);
	#else
		float alpha = 1.0;
	#endif
	if (alpha < 0.5)
	{
		discard;
	}
    #endif
    
    o_color = vec4(1.0);
}
