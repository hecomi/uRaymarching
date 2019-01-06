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

inline float3 GetDistanceFunctionNormal(float3 pos)
{
    const float d = 0.0001;
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

float _MinDistance;
int _Loop;

inline void InitRaymarchFullScreen(out RaymarchInfo ray, float4 screenPos)
{
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = GetCameraDirection(screenPos);
    ray.startPos = GetCameraPosition() + GetCameraNearClip() * ray.rayDir;
    ray.minDistance = _MinDistance;
    ray.maxDistance = GetCameraFarClip();
    ray.maxLoop = _Loop;
}

inline void InitRaymarchObject(out RaymarchInfo ray, float3 worldPos, float3 worldNormal)
{
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = normalize(worldPos - GetCameraPosition());
    ray.startPos = worldPos;
#ifdef CAMERA_INSIDE_OBJECT
    float3 startPos = GetCameraPosition() + (GetCameraNearClip() + 0.01) * ray.rayDir;
    if (IsInnerObject(startPos)) {
        ray.startPos = startPos;
    }
#endif
    ray.polyNormal = worldNormal;
    ray.maxDistance = GetCameraFarClip();
    ray.minDistance = _MinDistance;
    ray.maxLoop = _Loop;
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
    #define INITIALIZE_RAYMARCH_INFO(ray, i) \
        InitRaymarchFullScreen(ray, i.screenPos);
#elif defined(USE_CAMERA_DEPTH_TEXTURE)
    #define INITIALIZE_RAYMARCH_INFO(ray, i) \
        InitRaymarchObject(ray, i.worldPos, i.worldNormal); \
        UseCameraDepthTextureForMaxDistance(ray, i.projPos);
#else
    #define INITIALIZE_RAYMARCH_INFO(ray, i) \
        InitRaymarchObject(ray, i.worldPos, i.worldNormal);
#endif

inline bool _Raymarch(inout RaymarchInfo ray)
{
    ray.endPos = ray.startPos;
    ray.lastDistance = 0.0;
    ray.totalLength = length(ray.startPos - GetCameraPosition());

    for (ray.loop = 0; ray.loop < ray.maxLoop; ++ray.loop) {
        ray.lastDistance = _DistanceFunction(ray.endPos);
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
    ray.normal = EncodeNormal(normal);
    ray.depth = GetCameraDepth(ray.endPos);
    return;
#endif

#ifdef CAMERA_INSIDE_OBJECT
    if (IsInnerObject(GetCameraPosition()) && ray.totalLength < GetCameraNearClip()) {
        ray.normal = EncodeNormal(-ray.rayDir);
        ray.depth = GetCameraDepth(ray.startPos);
        return;
    }
#endif

    float initLength = length(ray.startPos - GetCameraPosition());
    if (ray.totalLength - initLength < ray.minDistance) {
        ray.normal = EncodeNormal(ray.polyNormal);
        ray.depth = GetCameraDepth(ray.startPos) - 1e-6;
    } else {
        float3 normal = GetDistanceFunctionNormal(ray.endPos);
        ray.normal = EncodeNormal(normal);
        ray.depth = GetCameraDepth(ray.endPos);
    }
}

#endif
