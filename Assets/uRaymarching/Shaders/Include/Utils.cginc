#ifndef UTILS_H
#define UTILS_H

inline float3 ToLocal(float3 pos)
{
    return mul(unity_WorldToObject, float4(pos, 1.0)).xyz;
}

inline float3 ToWorld(float3 pos)
{
    return mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
}

inline float GetDepth(float3 pos)
{
    float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
    float z = vpPos.z / vpPos.w;
#if defined(SHADER_API_GLCORE) || \
    defined(SHADER_API_OPENGL) || \
    defined(SHADER_API_GLES) || \
    defined(SHADER_API_GLES3)
    return z * 0.5 + 0.5;
#else 
    return z;
#endif 
}

inline float3 EncodeNormal(float3 normal)
{
    return normal * 0.5 + 0.5;
}

inline bool IsInnerCube(float3 pos, float3 scale)
{
    return all(max(scale * 0.5 - abs(pos), 0.0));
}

inline bool IsInnerSphere(float3 pos, float3 scale)
{
    return length(pos) <= length(scale) * 0.28867513459;
}

inline bool __IsInnerObject(float3 pos, float3 scale)
{
#ifdef OBJECT_SHAPE_CUBE
    return IsInnerCube(pos, scale);
#elif OBJECT_SHAPE_SPHERE
    return IsInnerSphere(pos, scale);
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
    return _IsInnerObject(ToLocal(pos), abs(_Scale));
#endif
}

#endif
