#ifndef URAYMARCHING_STRUCTS_HLSL
#define URAYMARCHING_STRUCTS_HLSL

struct RaymarchInfo
{
    // Input
    float3 startPos;
    float3 rayDir;
    float3 polyPos;
    float3 polyNormal;
    float4 projPos;
    float minDistance;
    float maxDistance;
    int maxLoop;

    // Output
    int loop;
    float3 endPos;
    float lastDistance;
    float totalLength;
    float depth;
    float3 normal;
};

#endif