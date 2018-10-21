#version 430

layout(local_size_x = 1, local_size_y = 1) in;

uniform isampler1D histogram_texture;
layout(rgba32f) uniform image2D debug_texture;

void main()
{
	
	for (int i = 0; i < 16; i++)
    {
        float pixels = texelFetch(histogram_texture, i, 0).r / 4000.0;
        imageStore(debug_texture, ivec2(i, 0), vec4(pixels, pixels, pixels, 1.0));
    }
}