#version 330

in vec4 l_texcoord;

out vec4 outputColor;

uniform sampler2D skyboxRTT;

void main()
{
    outputColor = textureProj(skyboxRTT, l_texcoord);
}
