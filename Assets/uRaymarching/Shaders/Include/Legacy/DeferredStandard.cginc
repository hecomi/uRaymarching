#ifndef VERT_FRAG_DEFERRED_OBJECT_STANDARD_H
#define VERT_FRAG_DEFERRED_OBJECT_STANDARD_H

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"

#include "./Structs.cginc"
#include "./Raymarching.cginc"
#include "./Utils.cginc"

int _Loop;
float _MinDistance;
fixed4 _Color;
float _Glossiness;
float _Metallic;

#ifdef FULL_SCREEN

struct v2f
{
    float4 pos         : SV_POSITION;
    float4 projPos     : TEXCOORD0;
    float4 lmap        : TEXCOORD1;
#ifdef LIGHTMAP_OFF
    #if UNITY_SHOULD_SAMPLE_SH
    half3 sh           : TEXCOORD2;
    #endif
#endif
};

#else

struct v2f
{
    float4 pos         : SV_POSITION;
    float3 worldPos    : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float4 projPos     : TEXCOORD2;
    float4 lmap        : TEXCOORD3;
#ifdef LIGHTMAP_OFF
    #if UNITY_SHOULD_SAMPLE_SH
    half3 sh           : TEXCOORD4;
    #endif
#endif
};

#endif

v2f Vert(appdata_full v)
{
    v2f o;

#ifdef FULL_SCREEN
    o.pos = v.vertex;
#else
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
#endif
    o.projPos = ComputeNonStereoScreenPos(o.pos);
    COMPUTE_EYEDEPTH(o.projPos.z);

#ifndef DYNAMICLIGHTMAP_OFF
    o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#else
    o.lmap.zw = 0;
#endif

#ifndef LIGHTMAP_OFF
    o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#else
    o.lmap.xy = 0;
    #ifndef SPHERICAL_HARMONICS_PER_PIXEL
        #if UNITY_SHOULD_SAMPLE_SH
    o.sh = 0;
    o.sh = ShadeSHPerVertex(o.worldNormal, o.sh);
        #endif
    #endif
#endif

    return o;
}

GBufferOut Frag(v2f i, GBufferOut o)
{
    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, i, _Loop, _MinDistance);
    Raymarch(ray);

#ifdef USE_RAYMARCHING_DEPTH
    o.depth = ray.depth;
#endif

    float3 worldPos = ray.endPos;
    float3 worldNormal = 2.0 * ray.normal - 1.0;
    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

    SurfaceOutputStandard so;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, so);
    so.Albedo = _Color.rgb;
    so.Metallic = _Metallic;
    so.Smoothness = _Glossiness;
    so.Emission = 0.0;
    so.Alpha = _Color.a;
    so.Occlusion = 1.0;
    so.Normal = worldNormal;

#ifdef POST_EFFECT
    POST_EFFECT(ray, so);
#endif

    UnityGI gi;
    UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
    gi.indirect.diffuse = 0;
    gi.indirect.specular = 0;
    gi.light.color = 0;
    gi.light.dir = half3(0, 1, 0);
    gi.light.ndotl = LambertTerm(worldNormal, gi.light.dir);

    UnityGIInput giInput;
    UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
    giInput.light = gi.light;
    giInput.worldPos = worldPos;
    giInput.worldViewDir = worldViewDir;
    giInput.atten = 1;

#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    giInput.lightmapUV = i.lmap;
#else
    giInput.lightmapUV = 0.0;
#endif

#if UNITY_SHOULD_SAMPLE_SH
    #ifdef SPHERICAL_HARMONICS_PER_PIXEL
    giInput.ambient = ShadeSHPerPixel(worldNormal, 0.0, worldPos);
    #else
    giInput.ambient.rgb = i.sh;
    #endif
#else
    giInput.ambient.rgb = 0.0;
#endif

    giInput.probeHDR[0] = unity_SpecCube0_HDR;
    giInput.probeHDR[1] = unity_SpecCube1_HDR;

#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#endif

#if UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif

    LightingStandard_GI(so, giInput, gi);

    o.emission = LightingStandard_Deferred(so, worldViewDir, gi, o.diffuse, o.specular, o.normal);
#ifndef UNITY_HDR_ON
    o.emission.rgb = exp2(-o.emission.rgb);
#endif

    UNITY_OPAQUE_ALPHA(o.diffuse.a);

    return o;
}

#endif
