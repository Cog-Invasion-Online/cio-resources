#version 330

const int NUM_SPLITS = 3;

uniform mat4 split_mvps[NUM_SPLITS];

layout(triangles) in;
layout(triangle_strip, max_vertices = 9) out; // NUM_SPLITS * 3

void main()
{
	// for each pssm split
	for (int i = 0; i < NUM_SPLITS; i++)
	{
		gl_Layer = i;
		// reverse the winding order of the primitive
		// helps to alleviate shadow map artifacts
		for (int j = 0; j < 3; j++)
		{
			// project this vertex into clip space of this pssm split camera
			gl_Position = split_mvps[i] * gl_in[j].gl_Position;
			EmitVertex();
		}
		EndPrimitive();
	}
}
