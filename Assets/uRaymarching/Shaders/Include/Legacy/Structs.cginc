#ifndef STRUCTS_CGINC
#define STRUCTS_CGINC

struct GBufferOut
{
    half4 diffuse  : SV_Target0; // rgb: diffuse,  a: occlusion
    half4 specular : SV_Target1; // rgb: specular, a: smoothness
    half4 normal   : SV_Target2; // rgb: normal,   a: unused
    half4 emission : SV_Target3; // rgb: emission, a: unused
#ifdef USE_RAYMARCHING_DEPTH
    float depth    : SV_Depth;
#endif
};

struct RaymarchInfo
{
    // Input
    float3 startPos;
    float3 rayDir;
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
