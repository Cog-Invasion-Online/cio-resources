#version 430

uniform sampler2D p3d_Texture0;
in vec2 texcoord;
out vec4 frag_color;
in vec4 ambient_term;
in vec4 vtx_color;
in vec4 eye_position;
in vec4 eye_normal;

uniform vec4 p3d_ColorScale;
uniform mat4 p3d_ViewMatrix;

// Factor in up to two local lights.
uniform int num_locallights[1];
uniform int locallight_type[2];
uniform struct
{
        vec3 pos;
        vec4 direction;
        vec4 atten;
        vec3 color;
} locallight[2];

const int LIGHTTYPE_SUN = 0;
const int LIGHTTYPE_POINT = 1;
const int LIGHTTYPE_SPOT = 2;

void main()
{
        // First start with constant ambient term.
        // Vertex color was combined with ambient term in the vertex shader.
        frag_color = ambient_term;
        
        // Now factor in local light sources.
        vec3 totallight = vec3(0, 0, 0);
        for (int i = 0; i < num_locallights[0]; i++)
        {
                if (locallight_type[i] == LIGHTTYPE_POINT)
                {
                        vec4 lightpos = p3d_ViewMatrix * vec4(locallight[i].pos, 1);
                        vec3 lightvec = lightpos.xyz - eye_position.xyz;
                        float lightdist = length(lightvec);
                        lightvec = normalize(lightvec);
                        
                        float dot = clamp(dot(eye_normal.xyz, lightvec), 0, 1);
                        float atten = lightdist * lightdist * locallight[i].atten.x;
                        float ratio = dot / atten;
                        totallight += (locallight[i].color * ratio);
                }
                else if (locallight_type[i] == LIGHTTYPE_SUN)
                {
                        vec3 lightvec = locallight[i].direction.xyz;
                        float intensity = clamp(dot(eye_normal.xyz, lightvec), 0, 1);
                        totallight += (locallight[i].color * intensity);
                }
                else if (locallight_type[i] == LIGHTTYPE_SPOT)
                {
                        vec3 lightvec = locallight[i].pos - eye_position.xyz;
                        float dist = length(lightvec);
                        lightvec /= dist;
                        float angle = clamp(dot(locallight[i].direction.xyz, lightvec), 0, 1);
                        vec4 atten = locallight[i].atten;
                        float attenv = 1.0 / (atten.x + atten.y*dist + atten.z*dist*dist);
                        attenv *= pow(angle, atten.w);
                        if (angle < locallight[i].direction.w)
                        {
                                attenv = 0.0;
                        }
                        float intensity = clamp(dot(eye_normal.xyz, lightvec), 0, 1);
                        totallight += (locallight[i].color * attenv * intensity);
                }
        }
        
        frag_color.rgb += totallight;
        
        frag_color *= vtx_color;
        // Combine with any colors applied to the model itself.
        frag_color *= p3d_ColorScale;
        // Combine with albedo texture.
        frag_color *= texture( p3d_Texture0, texcoord );
}