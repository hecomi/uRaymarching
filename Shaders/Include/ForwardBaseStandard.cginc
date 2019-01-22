#ifndef VERT_FRAG_FORWARD_OBJECT_STANDARD_BASE_H
#define VERT_FRAG_FORWARD_OBJECT_STANDARD_BASE_H

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
float _Glossiness;
float _Metallic;

#ifdef FULL_SCREEN

struct VertOutput
{
    UNITY_POSITION(pos);
    float4 projPos : TEXCOORD0;
    float4 lmap : TEXCOORD1;
    UNITY_SHADOW_COORDS(2)
    UNITY_FOG_COORDS(3)
#ifndef SPHERICAL_HARMONICS_PER_PIXEL
    #ifndef LIGHTMAP_ON
        #if UNITY_SHOULD_SAMPLE_SH
        half3 sh : TEXCOORD4;
        #endif
    #endif
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#else

struct VertOutput
{
    UNITY_POSITION(pos);
    float4 projPos : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    float4 lmap : TEXCOORD3;
    UNITY_SHADOW_COORDS(4)
    UNITY_FOG_COORDS(5)
#ifndef SPHERICAL_HARMONICS_PER_PIXEL
    #ifndef LIGHTMAP_ON
        #if UNITY_SHOULD_SAMPLE_SH
        half3 sh : TEXCOORD6;
        #endif
    #endif
#endif
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

VertOutput Vert(appdata_full v)
{
    VertOutput o;
    UNITY_INITIALIZE_OUTPUT(VertOutput, o);

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

#ifdef FULL_SCREEN
    o.pos = v.vertex;
#else
    o.pos = UnityObjectToClipPos(v.vertex);
    #ifdef DISABLE_VIEW_CULLING
    o.pos.z = 1;
    #endif
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
#endif
    o.projPos = ComputeNonStereoScreenPos(o.pos);
    COMPUTE_EYEDEPTH(o.projPos.z);

#ifdef DYNAMICLIGHTMAP_ON
    o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
#ifdef LIGHTMAP_ON
    o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
#if !defined(FULL_SCREEN) && !defined(SPHERICAL_HARMONICS_PER_PIXEL)
    #ifndef LIGHTMAP_ON
        #if UNITY_SHOULD_SAMPLE_SH
            o.sh = 0;
            #ifdef VERTEXLIGHT_ON
                o.sh += Shade4PointLights(
                    unity_4LightPosX0, 
                    unity_4LightPosY0, 
                    unity_4LightPosZ0,
                    unity_LightColor[0].rgb, 
                    unity_LightColor[1].rgb, 
                    unity_LightColor[2].rgb, 
                    unity_LightColor[3].rgb,
                    unity_4LightAtten0, 
                    o.worldPos, 
                    o.worldNormal);
            #endif
            o.sh = ShadeSHPerVertex(o.worldNormal, o.sh);
        #endif
    #endif
#endif

    UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);
    //UNITY_TRANSFER_FOG(o,o.pos);
    return o;
}

FragOutput Frag(VertOutput i)
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, i, _Loop, _MinDistance);
    Raymarch(ray);

    float3 worldPos = ray.endPos;
    float3 worldNormal = 2.0 * ray.normal - 1.0;
    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
#ifdef USING_DIRECTIONAL_LIGHT
    fixed3 lightDir = _WorldSpaceLightPos0.xyz;
#else
    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#endif

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

    UNITY_LIGHT_ATTENUATION(atten, i, worldPos)

    UnityGI gi;
    UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
    gi.indirect.diffuse = 0;
    gi.indirect.specular = 0;
    gi.light.color = _LightColor0.rgb;
    gi.light.dir = lightDir;

    UnityGIInput giInput;
    UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
    giInput.light = gi.light;
    giInput.worldPos = worldPos;
    giInput.worldViewDir = worldViewDir;
    giInput.atten = atten;

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

#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    giInput.boxMin[0] = unity_SpecCube0_BoxMin;
#endif

#ifdef UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif

    float4 color = 0.0;
    LightingStandard_GI(so, giInput, gi);
    color += LightingStandard(so, worldViewDir, gi);
    color.rgb += so.Emission;

    FragOutput o;
    UNITY_INITIALIZE_OUTPUT(FragOutput, o);
    o.color = color;
#ifdef USE_RAYMARCHING_DEPTH
    o.depth = ray.depth;
#endif

#if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
    i.fogCoord.x = mul(UNITY_MATRIX_VP, float4(ray.endPos, 1.0)).z;
#endif
    UNITY_APPLY_FOG(i.fogCoord, o.color);

    return o;
}

#endif
