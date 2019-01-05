#ifndef VERT_FRAG_DEFERRED_OBJECT_DIRECT_H
#define VERT_FRAG_DEFERRED_OBJECT_DIRECT_H

#include "UnityCG.cginc"
#include "./Structs.cginc"
#include "./Raymarching.cginc"
#include "./Utils.cginc"

float _MinDistance;
int _Loop;
float4 _Diffuse;
float4 _Specular;
float4 _Emission;

struct appdata
{
    float4 vertex : POSITION;
#ifndef WORLD_SPACE
    float3 normal : NORMAL;
#endif
};

struct v2f
{
    float4 vertex    : SV_POSITION;
#ifdef WORLD_SPACE
    float4 screenPos : TEXCOORD0;
#else
    float4 worldPos    : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
#endif
};

v2f Vert(appdata i)
{
    v2f o;
#ifdef WORLD_SPACE
    o.vertex = i.vertex;
    o.screenPos = i.vertex;
#else
    o.vertex = UnityObjectToClipPos(i.vertex);
    o.worldPos = mul(unity_ObjectToWorld, i.vertex);
    o.worldNormal = UnityObjectToWorldNormal(i.normal);
#endif
    return o;
}

GBufferOut Frag(v2f i)
{
    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);

#ifdef WORLD_SPACE
    ray.rayDir = GetCameraDirection(i.screenPos);
    ray.startPos = GetCameraPosition() + GetCameraNearClip() * ray.rayDir;
    ray.maxDistance = GetCameraFarClip();
#else
    ray.rayDir = normalize(i.worldPos - GetCameraPosition());
    ray.startPos = i.worldPos;
    ray.polyNormal = i.worldNormal;
    ray.maxDistance = GetCameraFarClip();
#endif
    ray.minDistance = _MinDistance;
    ray.maxLoop = _Loop;

    Raymarch(ray);

    GBufferOut o;
    UNITY_INITIALIZE_OUTPUT(GBufferOut, o);
    o.diffuse  = _Diffuse;
    o.specular = _Specular;
    o.emission = _Emission;
    o.normal   = float4(ray.normal, 1.0);
#ifdef USE_RAYMARCHING_DEPTH
    o.depth    = ray.depth;
#endif

#ifdef POST_EFFECT
    POST_EFFECT(ray, o);
#endif

#ifndef UNITY_HDR_ON
    o.emission = exp2(-o.emission);
#endif

    return o;
}

#endif
