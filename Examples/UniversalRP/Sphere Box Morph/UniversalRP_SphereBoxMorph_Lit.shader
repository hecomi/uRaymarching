Shader "Raymarching/UniversalRP_SphereBoxMorph_Lit"
{

Properties
{
    [Header(Base)]
    [MainColor] _BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1)
    [HideInInspector][MainTexture] _BaseMap("Albedo", 2D) = "white" {}
    [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

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
    _ShadowExtraBias("Shadow Extra Bias", Range(-1.0, 1.0)) = 0.01
    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
// _Color2("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
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

LOD 300

HLSLINCLUDE

#define OBJECT_SHAPE_CUBE

#define CHECK_IF_INSIDE_OBJECT

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect

#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Primitives.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Math.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Structs.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Utils.hlsl"

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

#define PostEffectOutput SurfaceData

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
}
// @endblock

ENDHLSL

Pass
{
    Name "ForwardLit"
    Tags { "LightMode" = "UniversalForward" }

    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _NORMALMAP
    #pragma shader_feature _ALPHATEST_ON
    #pragma shader_feature _ALPHAPREMULTIPLY_ON
    #pragma shader_feature _EMISSION
    #pragma shader_feature _METALLICSPECGLOSSMAP
    #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    #pragma shader_feature _OCCLUSIONMAP
    #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
    #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
    #pragma shader_feature _SPECULAR_SETUP
    #pragma shader_feature _RECEIVE_SHADOWS_OFF

    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Shaders\Include\UniversalRP/ForwardLit.hlsl"

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

    #pragma shader_feature _ALPHATEST_ON
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Shaders\Include\UniversalRP/DepthOnly.hlsl"

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

    #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Shaders\Include\UniversalRP/ShadowCaster.hlsl"

    ENDHLSL
}

}

FallBack "Hidden/Universal Render Pipeline/FallbackError"
CustomEditor "uShaderTemplate.MaterialEditor"

}