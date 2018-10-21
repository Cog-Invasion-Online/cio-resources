#version 430

layout (local_size_x = 1, local_size_y = 1) in;

uniform isampler1D histogram_texture;
layout(r16f) uniform image1D avg_lum_texture;

uniform float osg_DeltaFrameTime;

uniform vec2 bucketrange[16];

uniform vec2 exposure_minmax;
uniform vec2 adaption_rate_brightdark;
uniform float exposure_scale;

uniform float config_minAvgLum;
uniform float config_perctBrightPixels;
uniform float config_perctTarget;

float findLocationOfPercentBrightPixels(float perctBrightPixels, float sameBinSnap,
                                        uint pixelsPerBucket[16], uint num_pixels)
{
    // Find where percent range border is
    float rangeTested = 0.0;
    float pixelsTested = 0.0;
    // Starts at bright end
    for (int i = 15; i >= 0; i--)
    {
        float pixelPerctNeeded = (perctBrightPixels / 100.0) - pixelsTested;
        float binPerct = float(pixelsPerBucket[i]) / float(num_pixels);
        float binRange = bucketrange[i].y - bucketrange[i].x;
        if (binPerct >= pixelPerctNeeded)
        {
            // We found the bin needed
            if (sameBinSnap >= 0.0)
            {
                if (bucketrange[i].x <= (sameBinSnap / 100.0) && bucketrange[i].y >= (sameBinSnap / 100.0))
                {
                    // Sticky bin...
                    // We're in the same bin as the target, so keep the tonemap scale
                    // where it is.
                    return (sameBinSnap / 100.0);
                }
            }
            
            float perctTheseNeeded = pixelPerctNeeded / binPerct;
            float perctLocation = 1.0 - (rangeTested + (binRange * perctTheseNeeded));
            // Clamp to this bin just in case
            perctLocation = clamp(perctLocation, bucketrange[i].x, bucketrange[i].y);
            return perctLocation;
        }
        
        pixelsTested += binPerct;
        rangeTested += binRange;
    }
    
    return -1.0;
}

void main()
{
    uint pixelsPerBucket[16];
    
    uint num_pixels = 0;
    
    // Sample histogram texture to get number of pixels in each bucket.
    for (int i = 0; i < 16; i++)
    {
        int pixelsInBucket = texelFetch(histogram_texture, i, 0).r;
        pixelsPerBucket[i] = pixelsInBucket;
        num_pixels += pixelsInBucket;
    }
    
    float perctLocationOfTarget = findLocationOfPercentBrightPixels(
        config_perctBrightPixels, config_perctTarget,
        pixelsPerBucket, num_pixels);
        
    if (perctLocationOfTarget < 0.0)
    {
        // This is the return error code.
        // Pretend we're at the target.
        perctLocationOfTarget = config_perctTarget / 100.0;
    }
    
    // Make sure this is > 0
    perctLocationOfTarget = max(0.0001, perctLocationOfTarget);
    
    // Compute target scalar
    float targetScalar = (config_perctTarget / 100.0) / perctLocationOfTarget;
    
    // Compute secondary target scalar
    float avgLumLocation = findLocationOfPercentBrightPixels(
        50.0, -1.0, pixelsPerBucket, num_pixels);
    if (avgLumLocation > 0.0)
    {
        float targetScalar2 = (config_minAvgLum / 100.0) / avgLumLocation;
        
        // Only override it if it's trying to brighten the image more than the primary algorithm
        if (targetScalar2 > targetScalar)
        {
            targetScalar = targetScalar2;
        }
    }
    
    targetScalar = max(0.001, targetScalar);
    
    float exposure = targetScalar * exposure_scale;
    
    exposure = clamp(exposure, exposure_minmax.x, exposure_minmax.y);
    
    float curr_exposure = imageLoad(avg_lum_texture, 0).x;
    float adaption_rate = adaption_rate_brightdark.x;
    if (curr_exposure < exposure)
    {
        adaption_rate = adaption_rate_brightdark.y;
    }
    
    float adjustment = clamp(osg_DeltaFrameTime * adaption_rate, 0, 1);
    float new_luminance = mix(curr_exposure, exposure, adjustment);
    new_luminance = max(new_luminance, 0.0);
    
    imageStore(avg_lum_texture, 0, vec4(new_luminance));
}