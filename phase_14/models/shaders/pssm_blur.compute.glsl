#version 430

layout(local_size_x = 16, local_size_y = 1, local_size_z = 3) in;

layout(rgba32f) uniform image2DArray pssm_splits_orig;
layout(rgba32f) uniform image2DArray pssm_splits_blurred;

void main()
{
    
}