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
uniform mat4 attr_material2;

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

uniform struct
{
		vec4 rimColor;
		float rimWidth;
} p3d_Material;

const int LIGHTTYPE_SUN = 0;
const int LIGHTTYPE_POINT = 1;
const int LIGHTTYPE_SPOT = 2;

float half_lambert(float dp)
{
        float hl = dp * 0.5;
        hl += 0.5;
        hl *= hl;
        return hl;
}

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
                        
                        float _dot = dot(eye_normal.xyz, lightvec);
                        _dot = half_lambert(_dot);
                        float atten = lightdist * locallight[i].atten.x;
                        float ratio = _dot / atten;
                        totallight += (locallight[i].color * ratio);
                }
                else if (locallight_type[i] == LIGHTTYPE_SUN)
                {
                        vec3 lightvec = normalize((p3d_ViewMatrix * locallight[i].direction).xyz);
                        float intensity = dot(eye_normal.xyz, -lightvec);
                        
                        totallight += (locallight[i].color * half_lambert(intensity));
                }
                else if (locallight_type[i] == LIGHTTYPE_SPOT)
                {
						vec4 lightpos = p3d_ViewMatrix * vec4(locallight[i].pos, 1);
						vec3 lightdir = normalize((p3d_ViewMatrix * locallight[i].direction).xyz);
                        vec3 lightvec = lightpos.xyz - eye_position.xyz;
                        float lightdist = length(lightvec);
                        lightvec = normalize(lightvec);

						float _dot = dot(eye_normal.xyz, lightvec);
                        _dot = half_lambert(_dot);
						float dot2 = dot(lightvec, normalize(-lightdir));
						if (dot2 <= locallight[i].atten.z)
						{
								// outside light cone
							    continue;
						}
						float denominator = lightdist * locallight[i].atten.x;
						float ratio = _dot * dot2 / denominator;
						if (dot2 <= locallight[i].atten.y)
						{
								ratio *= ( dot2 - locallight[i].atten.z ) / ( locallight[i].atten.y - locallight[i].atten.z );
						}
                        totallight += (locallight[i].color * ratio);
                }
        }
        
        frag_color.rgb += totallight;

		// rim lighting
		vec3 totalrim = vec3(0, 0, 0);
		if (p3d_Material.rimWidth > 0)
		{
			vec3 rim_eye_pos = normalize(-eye_position.xyz);
			float rim_intensity = p3d_Material.rimWidth - max(dot(rim_eye_pos, eye_normal.xyz), 0.0);
			rim_intensity = max(0.0, rim_intensity);
			totalrim += (rim_intensity * p3d_Material.rimColor.rgb);
		}
		frag_color.rgb += totalrim;
        
		// Combine with albedo texture.
		frag_color *= texture( p3d_Texture0, texcoord );
        frag_color *= vtx_color;
        // Combine with any colors applied to the model itself.
        frag_color *= p3d_ColorScale;
}