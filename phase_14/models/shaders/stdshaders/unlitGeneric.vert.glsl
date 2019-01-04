#version 150

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file unlitGeneric.vert.glsl
 * @author Brian Lach
 * @date December 30, 2018
 *
 */
 
uniform mat4 p3d_ModelViewProjectionMatrix;

in vec4 p3d_Vertex;
in vec2 texcoord;

out vec2 l_texcoord;

#ifdef FOG
out vec4 l_hPos;
#endif

#ifdef COLOR_VERTEX
in vec4 p3d_Color;
out vec4 l_color;
#endif

void main()
{
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    
    l_texcoord = texcoord;
    
#ifdef COLOR_VERTEX
	l_color = p3d_Color;
#endif
    
#ifdef FOG
	l_hPos = gl_Position;
#endif
}
