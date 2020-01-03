#ifndef URAYMARCHING_SHADOW_CASTER_HLSL
#define URAYMARCHING_SHADOW_CASTER_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "./Primitives.hlsl"
#include "./Raymarching.hlsl"

float3 _LightDirection;
float _ShadowExtraBias;
float _ShadowMinDistance;
int _ShadowLoop;

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 positionSS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct FragOutput
{
    float4 color : SV_Target;
    float depth : SV_Depth;
};

inline float3 CustomApplyShadowBias(float3 positionWS, float3 normalWS)
{
    positionWS += _LightDirection * _ShadowBias.xxx;
    positionWS += _LightDirection * _ShadowExtraBias;

    float invNdotL = 1.0 - saturate(dot(_LightDirection, normalWS));
    float scale = invNdotL * _ShadowBias.y;
    positionWS += normalWS * scale.xxx;

    return positionWS;
}

inline float4 GetShadowPositionHClip(float3 positionWS, float3 normalWS)
{
    positionWS = CustomApplyShadowBias(positionWS, normalWS);
    float4 positionCS = TransformWorldToHClip(positionWS);
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif
    return positionCS;
}

Varyings Vert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
    output.positionSS.z = -TransformWorldToView(output.positionWS).z;

    return output;
}

FragOutput Frag(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    RaymarchInfo ray = (RaymarchInfo)0;
    ray.startPos = input.positionWS;
    ray.minDistance = _ShadowMinDistance;
    ray.maxDistance = GetCameraFarClip();
    ray.maxLoop = _ShadowLoop;

    if (IsCameraPerspective()) {
        // spot light
        ray.rayDir = GetCameraDirection(input.positionSS);
    } else {
        // directional light
        ray.rayDir = GetCameraForward();
    }

    if (!_Raymarch(ray)) discard;

    float initLength = length(ray.startPos - GetCameraPosition());
    if (ray.totalLength - initLength < ray.minDistance) {
        ray.normal = EncodeNormalWS(ray.polyNormal);
        ray.depth = EncodeDepthWS(ray.startPos) - 1e-6;
        ray.endPos = ray.startPos;
    } else {
        float3 normal = GetDistanceFunctionNormal(ray.endPos);
        ray.normal = EncodeNormalWS(normal);
        ray.depth = EncodeDepthWS(ray.endPos);
    }

    float3 normalWS = DecodeNormalWS(ray.normal);
    float4 positionCS = GetShadowPositionHClip(ray.endPos, normalWS);

    FragOutput o;
    o.color = o.depth = EncodeDepthCS(positionCS);
    return o;
}

#endif