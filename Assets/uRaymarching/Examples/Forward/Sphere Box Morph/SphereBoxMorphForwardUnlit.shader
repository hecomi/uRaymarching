Shader "Raymarching/SphereBoxMorphForwardUnlit"
{

Properties
{
    [Header(Base)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2

    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching Settings)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 1.0)) = 0.01

// @block Properties
// _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
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

#define OBJECT_SHAPE_CUBE

#define USE_CAMERA_DEPTH_TEXTURE

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput float4

#include "Assets/uRaymarching/Shaders/Include/Common.cginc"

// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
    float t = _Time.x;
    float a = 6 * PI * t;
    float s = pow(sin(a), 2.0);
    float d1 = Sphere(pos, 0.75);
    float d2 = RoundBox(
        Repeat(pos, 0.2),
        0.1 - 0.1 * s,
        0.1 / length(pos * 2.0));
    return lerp(d1, d2, s);
}
// @endblock

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 lightDir = _WorldSpaceLightPos0;
    float light = (dot(ray.normal, lightDir) + 1.0) * 0.5;
    light *= 1.0 - 1.0 * ray.loop / ray.maxLoop;
    o *= light;
}
// @endblock

#include "Assets/uRaymarching/Shaders/Include/Raymarching.cginc"

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }

    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Assets/uRaymarching/Shaders/Include/VertFragForwardObjectSimple.cginc"
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
    #include "Assets/uRaymarching/Shaders/Include/VertFragShadowObject.cginc"
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