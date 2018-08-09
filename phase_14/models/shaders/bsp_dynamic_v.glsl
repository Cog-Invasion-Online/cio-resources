#version 430

in vec4 p3d_Vertex;
in vec2 p3d_MultiTexCoord0;
in vec3 p3d_Normal;
in vec4 p3d_Color;
out vec2 texcoord;
out vec4 ambient_term;
out vec4 vtx_color;
out vec4 eye_position;
out vec4 eye_normal;

uniform mat4 p3d_ModelViewProjectionMatrix;
uniform mat4 p3d_ModelMatrix;
uniform mat4 p3d_ModelViewMatrix;
uniform mat4 tpose_view_to_model;

uniform vec3 ambient_cube[6];

vec3 ambient_light( vec3 world_normal )
{
        vec3 n_sqr = world_normal * world_normal;
        int negative = 0;
        if ( n_sqr.x < 0.0 && n_sqr.y < 0.0 && n_sqr.z < 0.0 )
        {
                negative = 1;
        }
        vec3 linear = n_sqr.x * ambient_cube[negative]     +
                      n_sqr.y * ambient_cube[negative + 2] +
                      n_sqr.z * ambient_cube[negative + 4];
        return linear;
}

void main()
{
        texcoord = p3d_MultiTexCoord0;
        gl_Position = p3d_ModelViewProjectionMatrix * p3d_Vertex;
        eye_position = p3d_ModelViewMatrix * p3d_Vertex;
        eye_normal.xyz = normalize(mat3(tpose_view_to_model) * p3d_Normal);
        eye_normal.w = 0.0;
        
        vec3 world_normal = (p3d_ModelMatrix * vec4( p3d_Normal, 0.0 )).xyz;
        world_normal = normalize(world_normal);
        
        vec3 ambient = ambient_light( world_normal );
        ambient_term = vec4( ambient, 1.0 );
        // Combine ambient term with vertex color.
        vtx_color = p3d_Color;
}