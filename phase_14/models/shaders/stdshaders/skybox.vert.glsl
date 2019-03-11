#version 330

uniform mat4 p3d_ModelViewProjectionMatrix;
in vec4 p3d_Vertex;

out vec4 l_texcoord;

const mat4 scale_mat = mat4(vec4(0.5, 0.0, 0.0, 0.0),
                            vec4(0.0, 0.5, 0.0, 0.0),
                            vec4(0.0, 0.0, 0.5, 0.0),
                            vec4(0.5, 0.5, 0.5, 1.0));

void main()
{
    gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
        
    l_texcoord = (scale_mat * p3d_ModelViewProjectionMatrix) * p3d_Vertex;
}
