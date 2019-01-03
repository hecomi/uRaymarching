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

inline float3 GetDistanceFunctiontionNormal(float3 pos)
{
    const float d = 0.0001;
    return EncodeNormal(normalize(float3(
        _DistanceFunction(pos + float3(  d, 0.0, 0.0)) - _DistanceFunction(pos),
        _DistanceFunction(pos + float3(0.0,   d, 0.0)) - _DistanceFunction(pos),
        _DistanceFunction(pos + float3(0.0, 0.0,   d)) - _DistanceFunction(pos))));
}

#ifdef USE_CAMERA_DEPTH_TEXTURE
UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

inline float GetMaxDistanceFromDepthTexture(float4 projPos, float3 rayDir)
{
    float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(projPos)));
    float maxLen = depth / dot(rayDir, GetCameraForward());
    return maxLen;
}
#endif

inline bool _ShouldRaymarchFinish(RaymarchInfo ray)
{
    if (ray.lastDistance < ray.minDistance) return true;

#if defined(WORLD_SPACE) || defined(USE_CAMERA_DEPTH_TEXTURE)
    if (ray.totalLength > ray.maxDistance) return true;
#endif

#ifndef WORLD_SPACE
    if (!IsInnerObject(ray.endPos)) return true;
#endif

    return false;
}

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

#ifdef WORLD_SPACE
    ray.normal = GetDistanceFunctiontionNormal(ray.endPos);
    ray.depth = GetCameraDepth(ray.endPos);
#else

    #ifdef CAMERA_INSIDE_OBJECT
    if (IsInnerObject(GetCameraPosition()) && ray.totalLength < GetCameraNearClip()) {
        ray.normal = EncodeNormal(-ray.rayDir);
        ray.depth = GetCameraDepth(ray.startPos);
        return;
    }
    #endif

    if (ray.totalLength < ray.minDistance) {
        ray.normal = EncodeNormal(ray.polyNormal);
        ray.depth = GetCameraDepth(ray.startPos) - 1e-6;
    } else {
        ray.normal = GetDistanceFunctiontionNormal(ray.endPos);
        ray.depth = GetCameraDepth(ray.endPos);
    }
#endif
}

#endif
