#ifndef URAYMARCHING_UTILS_HLSL
#define URAYMARCHING_UTILS_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

inline float3 GetScale()
{
    return float3(
        length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)),
        length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)),
        length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z)));
}

inline float3 ToLocal(float3 pos)
{
    return mul(unity_WorldToObject, float4(pos, 1.0)).xyz;
}

inline float3 ToWorld(float3 pos)
{
    return mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
}

inline float EncodeDepthCS(float4 pos)
{
    float z = pos.z / pos.w;
#if defined(SHADER_API_GLCORE) || \
    defined(SHADER_API_OPENGL) || \
    defined(SHADER_API_GLES) || \
    defined(SHADER_API_GLES3)
    return z * 0.5 + 0.5;
#else 
    return z;
#endif 
}

inline float EncodeDepthWS(float3 positionWS)
{
    float4 positionCS = TransformWorldToHClip(positionWS);
    return EncodeDepthCS(positionCS);
}

inline float3 EncodeNormalWS(float3 normal)
{
    return normal * 0.5 + 0.5;
}

inline float3 DecodeNormalWS(float3 normal)
{
    return 2.0 * normal - 1.0;
}

inline float4 ComputeNonStereoScreenPos(float4 pos)
{
    float4 o = pos * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = pos.zw;
    return o;
}

inline bool IsInnerCube(float3 pos, float3 scale)
{
    return all(max(scale * 0.5 - abs(pos), 0.0));
}

inline bool IsInnerSphere(float3 pos, float3 scale)
{
    return length(pos) < length(scale) * 0.28867513459 * 0.1;
}

inline bool __IsInnerObject(float3 pos, float3 scale)
{
#ifdef OBJECT_SHAPE_CUBE
    return IsInnerCube(pos, scale);
#else
    return true;
#endif    
}

inline bool _IsInnerObject(float3 pos, float3 scale)
{
#ifdef OBJECT_SCALE
    return __IsInnerObject(pos, scale);
#else
    return __IsInnerObject(pos * scale, scale);
#endif
}

inline bool IsInnerObject(float3 pos)
{
#ifdef OBJECT_SCALE
    return _IsInnerObject(ToLocal(pos), 1.0);
#else
    return _IsInnerObject(ToLocal(pos), GetScale());
#endif
}

#endif
