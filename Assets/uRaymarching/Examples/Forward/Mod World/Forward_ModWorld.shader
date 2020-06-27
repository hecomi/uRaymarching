Shader "Raymarching/Forward_ModWorld"
{

Properties
{
    [Header(Base)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2

    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0

    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Parameters)]
_Grid("Grid", 2D) = "" {}
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define FULL_SCREEN

#define WORLD_SPACE

#define OBJECT_SHAPE_NONE

#define USE_RAYMARCHING_DEPTH

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput float4

#include "Assets\uRaymarching\Shaders\Include\Legacy/Common.cginc"

// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
    float r = abs(sin(2 * PI * _Time.y / 2.0));
    float d1 = RoundBox(Repeat(pos, float3(6, 6, 6)), 1 - r, r);
    float d2 = Sphere(pos, 3.0);
    float d3 = Plane(pos - float3(0, -3, 0), float3(0, 1, 0));
    return SmoothMin(SmoothMin(d1, d2, 1.0), d3, 1.0);
}
// @endblock

// @block PostEffect
sampler2D _Grid;
float4 _Grid_ST;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    // PostEffectOutput = float4

    float3 lightDir = _WorldSpaceLightPos0;
    float light = (dot(ray.normal, lightDir) + 1.0) * 0.5; // half lambert
    float ao = 1.0 - 1.0 * ray.loop / ray.maxLoop; // ambient occlusion using raymarching loop count

    o.rgb = abs(1.0 - Mod(ray.endPos * 0.1 + _Time.y, 2.0));
    o += tex2D(_Grid, ray.endPos.xy * _Grid_ST.xy + _Grid_ST.zw);
    o *= light * ao;
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }

    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Assets\uRaymarching\Shaders\Include\Legacy/ForwardBaseUnlit.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile_fwdbase
    ENDCG
}

}

Fallback Off

CustomEditor "uShaderTemplate.MaterialEditor"

}