#version 150

uniform mat4 p3d_ModelMatrix;
in vec4 p3d_Vertex;
uniform mat4 p3d_ModelViewProjectionMatrix;
in vec2 p3d_MultiTexCoord0;
out vec2 l_uv;
//out float l_depth;

void main()
{
	// move vertex into world space
    // as the geometry shader will multiply the vertex
    // by the world space view projection matrix of each pssm split
	gl_Position = p3d_ModelMatrix * p3d_Vertex;
    //vec4 projPos = p3d_ModelViewProjectionMatrix * p3d_Vertex;
    //l_depth = projPos.z / projPos.w;
    //l_depth = 0.5 + (l_depth * 0.5);
    
	l_uv = p3d_MultiTexCoord0;
}