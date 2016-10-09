#ifndef FRAGS_SHADOW_H
#define FRAGS_SHADOW_H

#include "UnityCG.cginc"
#include "./Structs.cginc"
#include "./Raymarching.cginc"
#include "./Utils.cginc"

float _ShadowMinDistance;
int _ShadowLoop;

VertShadowOutput Vert(VertShadowInput v)
{
    VertShadowOutput o;
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
    o.screenPos = o.pos;
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = v.normal;
    return o;
}

#ifdef SHADOWS_CUBE

float4 Frag(VertShadowOutput i) : SV_Target
{
    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = GetCameraDirectionForShadow(i.screenPos);
    ray.startPos = i.worldPos;
    ray.minDistance = _ShadowMinDistance;
    ray.maxDistance = GetCameraMaxDistance();
    ray.loop = _ShadowLoop;

    if (!_Raymarch(ray)) discard;

    i.vec = ray.endPos - _LightPositionRange.xyz;
    SHADOW_CASTER_FRAGMENT(i);
}

#else

void Frag(
    VertShadowOutput i, 
    out float4 outColor : SV_Target, 
    out float  outDepth : SV_Depth)
{
    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.startPos = i.worldPos;
    ray.minDistance = _ShadowMinDistance;
    ray.maxDistance = GetCameraMaxDistance();
    ray.loop = _ShadowLoop;

    // light direction of spot light
    if ((UNITY_MATRIX_P[3].x != 0.0) || 
        (UNITY_MATRIX_P[3].y != 0.0) || 
        (UNITY_MATRIX_P[3].z != 0.0)) {
        ray.rayDir = GetCameraDirectionForShadow(i.screenPos);
    }
    // light direction of directional light 
    else {
        ray.rayDir = -UNITY_MATRIX_V[2].xyz;
    }

    if (!_Raymarch(ray)) discard;

    float4 opos = mul(unity_WorldToObject, float4(ray.endPos, 1.0));
    opos = UnityClipSpaceShadowCasterPos(opos, i.normal);
    opos = UnityApplyLinearShadowBias(opos);

#if defined(SHADER_API_D3D9) || defined(SHADER_API_D3D11)
    outColor = outDepth = opos.z / opos.w;
#else 
    outColor = outDepth = opos.z / opos.w * 0.5 + 0.5;
#endif 
}

#endif


#endif