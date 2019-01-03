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

struct Vert2Frag
{
    float4 pos : POSITION;
    float3 worldNormal : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
    float4 lmap : TEXCOORD2;
    UNITY_SHADOW_COORDS(3)
    UNITY_FOG_COORDS(4)
#ifdef USE_CAMERA_DEPTH_TEXTURE
    float4 projPos : TEXCOORD5;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct FragOutput
{
    float4 color : SV_Target;
#ifdef USE_RAYMARCHING_DEPTH
    float depth : SV_Depth;
#endif
};

Vert2Frag Vert(appdata_full v)
{
    Vert2Frag o;
    UNITY_INITIALIZE_OUTPUT(Vert2Frag, o);

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = worldPos;
    o.worldNormal = worldNormal;

#ifdef USE_CAMERA_DEPTH_TEXTURE
    o.projPos = ComputeScreenPos(o.pos);
    COMPUTE_EYEDEPTH(o.projPos.z);
#endif

    UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);
    UNITY_TRANSFER_FOG(o,o.pos);
    return o;
}

FragOutput Frag(Vert2Frag i)
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
#ifdef USE_CAMERA_DEPTH_TEXTURE
    ray.maxDistance = GetMaxDistanceFromDepthTexture(i.projPos, ray.rayDir);
#else
    ray.maxDistance = GetCameraFarClip();
#endif
    ray.maxLoop = _Loop;

    Raymarch(ray);

    FragOutput o;
    UNITY_INITIALIZE_OUTPUT(FragOutput, o);
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
