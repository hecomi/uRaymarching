#ifndef URAYMARCHING_RAYMARCHING_HLSL
#define URAYMARCHING_RAYMARCHING_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "./Camera.hlsl"
#include "./Utils.hlsl"
#include "./Structs.hlsl"

#ifndef DISTANCE_FUNCTION
inline float _DefaultDistanceFunction(float3 pos)
{
    return Box(pos, 1.0);
}
#define DISTANCE_FUNCTION _DefaultDistanceFunction
#endif

inline float _DistanceFunction(float3 pos)
{
#ifdef WORLD_SPACE
    return DISTANCE_FUNCTION(pos);
#else
    #ifdef OBJECT_SCALE
    return DISTANCE_FUNCTION(ToLocal(pos));
    #else
    return DISTANCE_FUNCTION(ToLocal(pos) * GetScale());
    #endif
#endif
}

inline float3 GetDistanceFunctionNormal(float3 pos)
{
    const float d = 1e-4;
    return normalize(float3(
        _DistanceFunction(pos + float3(  d, 0.0, 0.0)) - _DistanceFunction(pos),
        _DistanceFunction(pos + float3(0.0,   d, 0.0)) - _DistanceFunction(pos),
        _DistanceFunction(pos + float3(0.0, 0.0,   d)) - _DistanceFunction(pos)));
}

inline bool _ShouldRaymarchFinish(RaymarchInfo ray)
{
    if (ray.lastDistance < ray.minDistance || ray.totalLength > ray.maxDistance) return true;

#if defined(OBJECT_SHAPE_CUBE) && !defined(FULL_SCREEN)
    if (!IsInnerObject(ray.endPos)) return true;
#endif

    return false;
}

inline void InitRaymarchFullScreen(out RaymarchInfo ray, float4 positionSS)
{
    ray = (RaymarchInfo)0;
    ray.rayDir = GetCameraDirection(positionSS);
    ray.projPos = positionSS;
#if defined(USING_STEREO_MATRICES)
    float3 cameraPos = unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
    cameraPos += float3(1., 0, 0) * unity_StereoEyeIndex;
#else
    float3 cameraPos = _WorldSpaceCameraPos;
#endif
    ray.startPos = cameraPos + GetCameraNearClip() * ray.rayDir;
    ray.maxDistance = GetCameraFarClip();
}

inline void InitRaymarchObject(out RaymarchInfo ray, float4 positionSS, float3 positionWS, float3 normalWS)
{
    ray = (RaymarchInfo)0;
    ray.rayDir = normalize(positionWS - GetCameraPosition());
    ray.projPos = positionSS;
    ray.startPos = positionWS;
    ray.polyPos = positionWS;
    ray.polyNormal = normalize(normalWS);
    ray.maxDistance = GetCameraFarClip();

#ifdef CAMERA_INSIDE_OBJECT
    float3 cameraNearPlanePos = GetCameraPosition() + GetDistanceFromCameraToNearClipPlane(positionSS) * ray.rayDir;
    if (IsInnerObject(cameraNearPlanePos)) {
        ray.startPos = cameraNearPlanePos;
        ray.polyNormal = -ray.rayDir;
    }
#endif
}

inline void InitRaymarchParams(inout RaymarchInfo ray, int maxLoop, float minDistance)
{
    ray.maxLoop = maxLoop;
    ray.minDistance = minDistance;
}

#if defined(USE_CAMERA_DEPTH_TEXTURE_FOR_DEPTH_TEST) || defined(USE_CAMERA_DEPTH_TEXTURE_FOR_START_POS)

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

inline void InitRaymarchWithCameraDepthTexture(inout RaymarchInfo ray, float3 positionWS, float4 positionSS)
{
    float2 uv = positionSS.xy / positionSS.w;
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
    depth = LinearEyeDepth(depth, _ZBufferParams);
    float dist = depth / dot(ray.rayDir, GetCameraForward());
#ifdef USE_CAMERA_DEPTH_TEXTURE_FOR_DEPTH_TEST
    ray.maxDistance = dist;
#else
    ray.startPos = GetCameraPosition() + ray.rayDir * dist;
#endif
}

#endif

#if defined(FULL_SCREEN)
    #define INITIALIZE_RAYMARCH_INFO(ray, i, loop, minDistance) \
        InitRaymarchFullScreen(ray, i.projPos); \
        InitRaymarchParams(ray, loop, minDistance);
#elif defined(USE_CAMERA_DEPTH_TEXTURE_FOR_DEPTH_TEST) || defined(USE_CAMERA_DEPTH_TEXTURE_FOR_START_POS)
    #define INITIALIZE_RAYMARCH_INFO(ray, i, loop, minDistance) \
        InitRaymarchObject(ray, i.positionSS, i.positionWS, i.normalWS); \
        InitRaymarchParams(ray, loop, minDistance); \
        InitRaymarchWithCameraDepthTexture(ray, i.positionWS, i.positionSS);
#else
    #define INITIALIZE_RAYMARCH_INFO(ray, i, loop, minDistance) \
        InitRaymarchObject(ray, i.positionSS, i.positionWS, i.normalWS); \
        InitRaymarchParams(ray, loop, minDistance);
#endif

float _DistanceMultiplier;

inline bool _Raymarch(inout RaymarchInfo ray)
{
    ray.endPos = ray.startPos;
    ray.lastDistance = 0.0;
    ray.totalLength = length(ray.endPos - GetCameraPosition());

    float multiplier = _DistanceMultiplier;
#ifdef OBJECT_SCALE
    float3 localRayDir = normalize(mul(unity_WorldToObject, ray.rayDir));
    multiplier *= length(mul(unity_ObjectToWorld, localRayDir));
#endif

    for (ray.loop = 0; ray.loop < ray.maxLoop; ++ray.loop) {
        ray.lastDistance = _DistanceFunction(ray.endPos) * multiplier;
        ray.totalLength += ray.lastDistance;
        ray.endPos += ray.rayDir * ray.lastDistance;
        if (_ShouldRaymarchFinish(ray)) break;
    }

    return ray.lastDistance < ray.minDistance;
}

void Raymarch(inout RaymarchInfo ray)
{
    if (!_Raymarch(ray)) discard;

#ifdef FULL_SCREEN
    float3 normal = GetDistanceFunctionNormal(ray.endPos);
    ray.normal = EncodeNormalWS(normal);
    ray.depth = EncodeDepthWS(ray.endPos);
    return;
#endif

#ifdef CAMERA_INSIDE_OBJECT
    if (IsInnerObject(GetCameraPosition()) && ray.totalLength < GetCameraNearClip()) {
        ray.normal = EncodeNormalWS(-GetCameraDirection());
        ray.depth = EncodeDepthWS(ray.startPos);
        ray.endPos = ray.startPos;
        return;
    }
#endif

    float lengthToPolySurface = length(ray.polyPos - GetCameraPosition());
    if (ray.totalLength - lengthToPolySurface < ray.minDistance) {
        ray.normal = EncodeNormalWS(ray.polyNormal);
        ray.depth = EncodeDepthWS(ray.polyPos) - 1e-6;
        ray.endPos = ray.startPos;
    } else {
        float3 normal = GetDistanceFunctionNormal(ray.endPos);
        ray.normal = EncodeNormalWS(normal);
        ray.depth = EncodeDepthWS(ray.endPos);
    }
}

#endif
