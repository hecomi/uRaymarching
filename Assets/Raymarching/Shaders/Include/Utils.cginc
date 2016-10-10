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
#if defined(SHADER_API_D3D9) || defined(SHADER_API_D3D11)
    return vpPos.z / vpPos.w;
#else 
    return (vpPos.z / vpPos.w) * 0.5 + 0.5;
#endif 
}

inline float EncodeNormal(float3 normal)
{
	return normal * 0.5 + 0.5;
}

inline bool IsInnerBox(float3 pos, float3 scale)
{
    return all(max(scale * 0.5 - abs(pos), 0.0));
}

inline bool IsInnerObject(float3 pos, float3 scale)
{
#ifdef OBJECT_SCALE
    return IsInnerBox(ToLocal(pos), scale);
#else
    return IsInnerBox(ToLocal(pos) * scale, scale);
#endif
}

#endif