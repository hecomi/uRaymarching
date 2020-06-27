#ifndef RAYMARCHING_CGINC
#define RAYMARCHING_CGINC

#include "UnityCG.cginc"
#include "./Camera.cginc"
#include "./Utils.cginc"

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

float _NormalDelta;

inline float3 GetDistanceFunctionNormal(float3 pos)
{
    const float d = _NormalDelta;
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

inline void InitRaymarchFullScreen(out RaymarchInfo ray, float4 projPos)
{
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = GetCameraDirection(projPos);
    ray.projPos = projPos;
#if defined(USING_STEREO_MATRICES)
    float3 cameraPos = unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
    cameraPos += float3(1., 0, 0) * unity_StereoEyeIndex;
#else
    float3 cameraPos = _WorldSpaceCameraPos;
#endif
    ray.startPos = cameraPos + GetCameraNearClip() * ray.rayDir;
    ray.maxDistance = GetCameraFarClip();
}

inline void InitRaymarchObject(out RaymarchInfo ray, float4 projPos, float3 worldPos, float3 worldNormal)
{
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = normalize(worldPos - GetCameraPosition());
    ray.projPos = projPos;
    ray.startPos = worldPos;
    ray.polyNormal = worldNormal;
    ray.maxDistance = GetCameraFarClip();

#ifdef CAMERA_INSIDE_OBJECT
    float3 cameraNearPlanePos = GetCameraPosition() + GetDistanceFromCameraToNearClipPlane(projPos) * ray.rayDir;
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

#ifdef USE_CAMERA_DEPTH_TEXTURE
UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

inline void UseCameraDepthTextureForMaxDistance(inout RaymarchInfo ray, float4 projPos)
{
    float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(projPos)));
    float dist = depth / dot(ray.rayDir, GetCameraForward());
    ray.maxDistance = dist;
}
#endif

#if defined(FULL_SCREEN)
    #define INITIALIZE_RAYMARCH_INFO(ray, i, loop, minDistance) \
        InitRaymarchFullScreen(ray, i.projPos); \
        InitRaymarchParams(ray, loop, minDistance);
#elif defined(USE_CAMERA_DEPTH_TEXTURE)
    #define INITIALIZE_RAYMARCH_INFO(ray, i, loop, minDistance) \
        InitRaymarchObject(ray, i.projPos, i.worldPos, i.worldNormal); \
        InitRaymarchParams(ray, loop, minDistance); \
        UseCameraDepthTextureForMaxDistance(ray, i.projPos);
#else
    #define INITIALIZE_RAYMARCH_INFO(ray, i, loop, minDistance) \
        InitRaymarchObject(ray, i.projPos, i.worldPos, i.worldNormal); \
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

    return ray.lastDistance < ray.minDistance;// && ray.totalLength < ray.maxDistance;
}

void Raymarch(inout RaymarchInfo ray)
{
    if (!_Raymarch(ray)) discard;

#ifdef FULL_SCREEN
    float3 normal = GetDistanceFunctionNormal(ray.endPos);
    ray.normal = EncodeNormal(normal);
    ray.depth = EncodeDepth(ray.endPos);
    return;
#endif

#ifdef CAMERA_INSIDE_OBJECT
    if (IsInnerObject(GetCameraPosition()) && ray.totalLength < GetCameraNearClip()) {
        ray.normal = EncodeNormal(-ray.rayDir);
        ray.depth = EncodeDepth(ray.startPos);
        return;
    }
#endif

    float initLength = length(ray.startPos - GetCameraPosition());
    if (ray.totalLength - initLength < ray.minDistance) {
        ray.normal = EncodeNormal(ray.polyNormal);
        ray.depth = EncodeDepth(ray.startPos) - 1e-6;
    } else {
        float3 normal = GetDistanceFunctionNormal(ray.endPos);
        ray.normal = EncodeNormal(normal);
        ray.depth = EncodeDepth(ray.endPos);
    }
}

#endif
