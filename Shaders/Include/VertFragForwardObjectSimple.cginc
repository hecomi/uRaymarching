#ifndef VERT_FRAG_FORWARD_OBJECT_SIMPLE_H
#define VERT_FRAG_FORWARD_OBJECT_SIMPLE_H

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#include "./Structs.cginc"
#include "./Raymarching.cginc"
#include "./Utils.cginc"

float _MinDistance;
int _Loop;
fixed4 _Color;

struct Vert2FragBase
{
    float4 pos : POSITION;
    float4 projPos : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    float4 lmap : TEXCOORD3;
    UNITY_SHADOW_COORDS(4)
    UNITY_FOG_COORDS(5)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct FragBaseOutput
{
    float4 color : SV_Target;
#ifdef USE_RAYMARCHING_DEPTH
    float depth : SV_Depth;
#endif
};

Vert2FragBase VertBase(appdata_full v)
{
    Vert2FragBase o;
    UNITY_INITIALIZE_OUTPUT(Vert2FragBase, o);

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = worldPos;
    o.worldNormal = worldNormal;

    UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);
    UNITY_TRANSFER_FOG(o,o.pos);
    return o;
}

FragBaseOutput FragBase(Vert2FragBase i)
{
    UNITY_SETUP_INSTANCE_ID(i);

    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = normalize(i.worldPos - GetCameraPosition());
    ray.startPos = i.worldPos;

#ifdef CAMERA_INSIDE_OBJECT
    float3 startPos = GetCameraPosition() + (GetCameraNearClip() + 0.01) * ray.rayDir;
    if (IsInnerObject(startPos)) {
        ray.startPos = startPos;
    }
#endif

    ray.polyNormal = i.worldNormal;
    ray.minDistance = _MinDistance;
    ray.maxDistance = GetCameraMaxDistance();
    ray.maxLoop = _Loop;

    Raymarch(ray);

    FragBaseOutput o;
    UNITY_INITIALIZE_OUTPUT(FragBaseOutput, o);
    o.color = _Color;
#ifdef USE_RAYMARCHING_DEPTH
    o.depth = ray.depth;
#endif

#ifdef POST_EFFECT
    POST_EFFECT(ray, o.color);
#endif

    UNITY_APPLY_FOG(i.fogCoord, o.color);

    return o;
}

#endif
