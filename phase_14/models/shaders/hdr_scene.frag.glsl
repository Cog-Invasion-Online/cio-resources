#version 330

in vec2 l_uv;
uniform sampler2D scene_tex;

out vec4 o_color;

void main()
{
	o_color = texture(scene_tex, l_uv);
}
