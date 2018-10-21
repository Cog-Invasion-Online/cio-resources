#version 430

layout(local_size_x = 16, local_size_y = 16) in;

uniform sampler2D scene_texture;
layout(r32i) uniform iimage1D histogram_texture;

uniform vec2 bucketrange[16];

int getBucketFromLuminance(float luminance)
{
    for (int i = 0; i < 16; i++)
    {
        if (luminance >= bucketrange[i].x && luminance < bucketrange[i].y)
        {
            // luminance falls into range of this bucket.
            return i;
        }
    }
    
    return -1;
}

void main()
{
    ivec2 coords = ivec2(gl_GlobalInvocationID.xy);

    // Extract color from scene.
    vec3 color = texelFetch(scene_texture, coords, 0).rgb;
    // Convert to luminance.
    float lum = ( 0.2125f * color.r ) + ( 0.7154f * color.g ) + ( 0.0721f * color.b );
    
    int bucket = getBucketFromLuminance(lum);
    if (bucket >= 0)
    {
        imageAtomicAdd(histogram_texture, bucket, 1);
    }
}