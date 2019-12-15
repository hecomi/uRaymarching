#ifndef VERT_FRAG_FORWARD_OBJECT_SIMPLE_H
#define VERT_FRAG_FORWARD_OBJECT_SIMPLE_H

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#include "./Structs.cginc"
#include "./Raymarching.cginc"
#include "./Utils.cginc"

int _Loop;
float _MinDistance;
fixed4 _Color;

#ifdef FULL_SCREEN

struct Vert2Frag
{
    float4 pos : POSITION;
    float4 projPos : TEXCOORD0;
    UNITY_SHADOW_COORDS(1)
    UNITY_FOG_COORDS(2)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#else

struct Vert2Frag
{
    float4 pos : POSITION;
    float4 projPos : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    UNITY_SHADOW_COORDS(3)
    UNITY_FOG_COORDS(4)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#endif

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

#ifdef FULL_SCREEN
    o.pos = v.vertex;
#else
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
#endif
    o.projPos = ComputeNonStereoScreenPos(o.pos);
    COMPUTE_EYEDEPTH(o.projPos.z);

    UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

FragOutput Frag(Vert2Frag i)
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    UNITY_SETUP_INSTANCE_ID(i);

    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, i, _Loop, _MinDistance);
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

#if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
    i.fogCoord.x = mul(UNITY_MATRIX_VP, float4(ray.endPos, 1.0)).z;
#endif
    UNITY_APPLY_FOG(i.fogCoord, o.color);

    return o;
}

#endif
