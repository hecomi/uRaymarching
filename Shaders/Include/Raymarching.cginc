#ifndef RAYMARCHING_CGINC
#define RAYMARCHING_CGINC

#include "UnityCG.cginc"
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

inline bool _ShouldRaymarchFinish(RaymarchInfo ray)
{
    if (ray.lastDistance < ray.minDistance) return true;

#ifdef WORLD_SPACE
    if (ray.totalLength > ray.maxDistance) return true;
#else
    if (!IsInnerObject(ray.endPos)) return true;
#endif

    return false;
}

inline bool _Raymarch(inout RaymarchInfo ray)
{
    ray.endPos = ray.startPos;
    ray.lastDistance = 0.0;
    ray.totalLength = 0.0;

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
        ray.depth = GetCameraDepth(ray.startPos);
    } else {
        ray.normal = GetDistanceFunctiontionNormal(ray.endPos);
        ray.depth = GetCameraDepth(ray.endPos);
    }
#endif
}

#endif
