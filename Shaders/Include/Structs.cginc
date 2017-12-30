#ifndef STRUCTS_H
#define STRUCTS_H

struct VertScreenInput
{
    float4 vertex : POSITION;
};

struct VertScreenOutput
{
    float4 vertex    : SV_POSITION;
    float4 screenPos : TEXCOORD0;
};

struct VertObjectInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};

struct VertStandardObjectOutput
{
    float4 pos         : SV_POSITION;
    float4 screenPos   : TEXCOORD0;
    float4 worldPos    : TEXCOORD1;
    float3 worldNormal : TEXCOORD2;
    float4 lmap        : TEXCOORD3;
#ifndef SPHERICAL_HARMONICS_PER_PIXEL
    #ifdef LIGHTMAP_OFF
        #if UNITY_SHOULD_SAMPLE_SH
    half3 sh           : TEXCOORD4;
        #endif
    #endif
#endif
};

struct VertObjectOutput
{
    float4 vertex      : SV_POSITION;
    float4 screenPos   : TEXCOORD0;
    float4 worldPos    : TEXCOORD1;
    float3 worldNormal : TEXCOORD2;
};

struct VertShadowInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv     : TEXCOORD0;
};

struct VertShadowOutput
{
    V2F_SHADOW_CASTER;
    float4 screenPos : TEXCOORD1;
    float4 worldPos  : TEXCOORD2;
    float3 normal    : TEXCOORD3;
};

struct GBufferOut
{
    half4 diffuse  : SV_Target0; // rgb: diffuse,  a: occlusion
    half4 specular : SV_Target1; // rgb: specular, a: smoothness
    half4 normal   : SV_Target2; // rgb: normal,   a: unused
    half4 emission : SV_Target3; // rgb: emission, a: unused
#ifndef DO_NOT_OUTPUT_DEPTH
    float depth    : SV_Depth;
#endif
};

struct RaymarchInfo
{
    // Input
    float3 startPos;
    float3 rayDir;
    float3 polyNormal;
    float minDistance;
    float maxDistance;
    int maxLoop;
    int loop;

    // Output
    float3 endPos;
    float lastDistance;
    float totalLength;
    float depth;
    float3 normal;
};

#endif
