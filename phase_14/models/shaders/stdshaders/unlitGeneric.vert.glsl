#version 330

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file unlitGeneric.vert.glsl
 * @author Brian Lach
 * @date December 30, 2018
 *
 */
 
#pragma include "phase_14/models/shaders/stdshaders/common_animation_vert.inc.glsl"
 
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
    vec4 finalVertex = p3d_Vertex;
    #if HAS_HARDWARE_SKINNING
	vec3 foo = vec3(0);
        DoHardwareAnimation(finalVertex, foo, p3d_Vertex, foo);
    #endif
    
    gl_Position = p3d_ModelViewProjectionMatrix * finalVertex;
    
    l_texcoord = texcoord;
    
#ifdef COLOR_VERTEX
	l_color = p3d_Color;
#endif
    
#ifdef FOG
	l_hPos = gl_Position;
#endif
}
