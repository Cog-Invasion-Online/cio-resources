#version 330

in vec3 l_worldEyeToVert;
uniform samplerCube skyboxSampler;

out vec4 outputColor;

void main()
{
    outputColor = texture(skyboxSampler, normalize(l_worldEyeToVert));
}
