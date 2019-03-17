#version 430

layout(local_size_x = 8, local_size_y = 8, local_size_z = 16) in;

uniform sampler2D scene_texture;
layout(r32i) uniform iimage1D histogram_texture;

uniform vec2 bucketrange[16];

const vec3 luminance_weights = vec3( 0.2125f, 0.7154f, 0.0721f );

void main()
{
    ivec2 coords = ivec2(gl_GlobalInvocationID.xy);

    // Extract color from scene.
    vec3 color = texelFetch(scene_texture, coords, 0).rgb;
    // Convert to luminance.
    float luminance = dot(color, luminance_weights);
    
    int i = int(gl_LocalInvocationID.z);
    if (luminance >= bucketrange[i].x && luminance < bucketrange[i].y)
    {
        // luminance falls into range of this bucket.
        imageAtomicAdd(histogram_texture, i, 1);
    }
}
