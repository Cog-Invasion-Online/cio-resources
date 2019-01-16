#version 330

uniform mat4 p3d_ModelMatrix;
in vec4 p3d_Vertex;

in vec2 texcoord;
out vec2 geo_uv;

void main()
{
	// move vertex into world space
    // as the geometry shader will multiply the vertex
    // by the world space view projection matrix of each pssm split
	gl_Position = p3d_ModelMatrix * p3d_Vertex;
    
	geo_uv = texcoord;
}
