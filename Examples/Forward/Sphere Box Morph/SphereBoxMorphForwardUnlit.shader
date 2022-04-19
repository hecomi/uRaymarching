Shader "Raymarching/SphereBoxMorphForwardUnlit"
{

Properties
{
    [Header(Base)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5 
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 0.1)) = 0.01
    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Properties)]
_Alpha("Alpha", Range(0.0, 1.0)) = 0.5
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Transparent"
    "Queue" = "Transparent"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define OBJECT_SHAPE_CUBE

#define USE_CAMERA_DEPTH_TEXTURE

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput float4

#include "Assets/uRaymarching/Runtime/Shaders/Include/Legacy/Common.cginc"

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
float _Alpha;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float ao = 1.0 - 1.0 * ray.loop / ray.maxLoop;
    o.rgb *= ao;
   o.a *= pow(ao, 3) * _Alpha;
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }

    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Assets/uRaymarching/Runtime/Shaders/Include/Legacy/ForwardBaseUnlit.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile_fwdbase
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ShadowCaster" }

    CGPROGRAM
    #include "Assets/uRaymarching/Runtime/Shaders/Include/Legacy/ShadowCaster.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma multi_compile_shadowcaster
    ENDCG
}

}

Fallback Off

CustomEditor "uShaderTemplate.MaterialEditor"

}