Shader "Raymarching/URP/Unlit"
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

// @block Properties
[Header(Additional Properties)]
_Alpha("Alpha", Range(0.0, 1.0)) = 0.5
// @endblock
}

SubShader
{

Tags 
{ 
    "RenderType" = "Opaque" 
    "Queue" = "Geometry"
    "IgnoreProjector" = "True" 
    "RenderPipeline" = "UniversalPipeline" 
    "DisableBatching" = "True"
}

LOD 100

HLSLINCLUDE

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define OBJECT_SHAPE_CUBE
#define USE_RAYMARCHING_DEPTH

#include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
#include "Assets/uRaymarching/Shaders/Include/SRP/Primitives.hlsl"
#include "Assets/uRaymarching/Shaders/Include/SRP/Math.hlsl"
#include "Assets/uRaymarching/Shaders/Include/SRP/Structs.hlsl"

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

#define PostEffectOutput float4

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float ao = 1.0 - pow(1.0 * ray.loop / ray.maxLoop, 2);
    o.rgb *= ao;
    o.a *= pow(ao, 3);
}

ENDHLSL

Pass
{
    Name "Unlit"

    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]
    Cull [_Cull]

    HLSLPROGRAM

    #define USE_CAMERA_DEPTH_TEXTURE_FOR_START_POS

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma shader_feature _ALPHAPREMULTIPLY_ON
    #pragma multi_compile_fog
    #pragma multi_compile_instancing
    #include "Assets/uRaymarching/Shaders/Include/SRP/ForwardUnlit.hlsl"

    ENDHLSL
}

Pass
{
    Name "DepthOnly"
    Tags { "LightMode" = "DepthOnly" }

    ZWrite On
    ColorMask 0
    Cull [_Cull]

    HLSLPROGRAM

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma shader_feature _ALPHATEST_ON
    #pragma multi_compile_instancing

    #include "Assets/uRaymarching/Shaders/Include/SRP/DepthOnly.hlsl"

    ENDHLSL
}

Pass
{
    Name "ShadowCaster"
    Tags { "LightMode" = "ShadowCaster" }

    ZWrite On
    ZTest LEqual
    Cull [_Cull]

    HLSLPROGRAM

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    #include "Assets/uRaymarching/Shaders/Include/SRP/ShadowCaster.hlsl"

    ENDHLSL
}

}

FallBack "Hidden/Universal Render Pipeline/FallbackError"

}