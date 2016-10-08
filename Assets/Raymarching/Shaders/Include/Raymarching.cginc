#ifndef RAYMARCHING_H
#define RAYMARCHING_H

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
	return DISTANCE_FUNCTION(ToLocal(pos) * abs(_Scale));
	#endif
#endif
}

inline float3 GetDistanceFunctiontionNormal(float3 pos)
{
    float d = 0.001;
    return 0.5 + 0.5 * normalize(float3(
        _DistanceFunction(pos + float3(  d, 0.0, 0.0)) - _DistanceFunction(pos),
        _DistanceFunction(pos + float3(0.0,   d, 0.0)) - _DistanceFunction(pos),
        _DistanceFunction(pos + float3(0.0, 0.0,   d)) - _DistanceFunction(pos)));
}

inline bool _Raymarch(inout RaymarchInfo ray)
{
	ray.endPos = ray.startPos;
	ray.lastDistance = 0.0;
	ray.totalLength = 0.0;

    for (int n = 0; n < ray.loop; ++n) {
        ray.lastDistance = _DistanceFunction(ray.endPos);
        ray.totalLength += ray.lastDistance;
        ray.endPos += ray.rayDir * ray.lastDistance;
#ifdef WORLD_SPACE
        if (ray.lastDistance < ray.minDistance || ray.totalLength > ray.maxDistance) break;
#else
	#ifdef OBJECT_SCALE
        if (ray.lastDistance < ray.minDistance || !IsInnerObject(ray.endPos, 1.0)) break;
	#else
        if (ray.lastDistance < ray.minDistance || !IsInnerObject(ray.endPos, abs(_Scale))) break;
	#endif
#endif
    }

    return ray.lastDistance - ray.minDistance < 0;
}

void Raymarch(inout RaymarchInfo ray)
{
	if (!_Raymarch(ray)) discard;

#ifdef WORLD_SPACE
    ray.normal = GetDistanceFunctiontionNormal(ray.endPos);
	ray.depth = GetDepth(ray.endPos);
#else
    if (ray.totalLength < 0.01) {
		ray.normal = ray.polyNormal * 0.5 + 0.5;
		ray.depth = GetDepth(ray.startPos);
	} else {
		ray.normal = GetDistanceFunctiontionNormal(ray.endPos);
		ray.depth = GetDepth(ray.endPos);
	}
#endif
}

#endif