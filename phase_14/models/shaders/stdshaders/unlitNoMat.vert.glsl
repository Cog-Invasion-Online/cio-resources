#version 330

/**
 * COG INVASION ONLINE
 * Copyright (c) CIO Team. All rights reserved.
 *
 * @file unlitNoMat.vert.glsl
 * @author Brian Lach
 * @date January 11, 2019
 *
 * This serves as a fallback shader when the RenderState does not contain a material.
 * It supports a single texture (specified through TextureAttrib), flat or vertex colors,
 * and color scale. This shader will most commonly occur in GUI, as GUI elements/models
 * don't have materials on them, or any RenderState that does not contain a BSPMaterialAttrib.
 *
 */
 
uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;

#ifdef HAS_TEXTURE
in vec2 p3d_MultiTexCoord0;
out vec2 l_texcoord;
#endif

#ifdef COLOR_VERTEX
in vec4 p3d_Color;
out vec4 l_color;
#endif

void main()
{
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    
#ifdef HAS_TEXTURE
    l_texcoord = p3d_MultiTexCoord0;
#endif
    
#ifdef COLOR_VERTEX
    l_color = p3d_Color;
#endif
}
