#version 330

uniform vec4 p3d_Color;
out vec4 o_color;

uniform sampler2D p3d_Texture0;
uniform float exp_factor[1];
in vec2 l_uv;
//in float l_depth;

float map_01(float x, float v0, float v1)
{
    return (x - v0) / (v1 - v0);
}

void main()
{

	// for transparent sprites
	//float alpha = texture(p3d_Texture0, l_uv).a;
	//if (alpha < 0.5)
	//{
	//	discard;
	//}
    
    //float depth_div = gl_FragCoord.z / gl_FragCoord.w;
    //float mapped_div = map_01(depth_div, 1.0, 400.0);
    
    //float l_depth = gl_FragCoord.z;
    
    //float depth2 = pow(l_depth, 2.0);
    
    //float dx = dFdx(l_depth);
    //float dy = dFdy(l_depth);
    //float depth2Avg = depth2 + 0.25 * (dx*dx + dy*dy);
	
    // in the color buffer, write depth to R channel, alpha to G channel
    // shadow factor is inversely related to alpha
	o_color = p3d_Color * texture(p3d_Texture0, l_uv);
    
}
