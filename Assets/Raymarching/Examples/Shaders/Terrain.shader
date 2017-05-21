Shader "Raymarching/Terrain"
{

Properties
{
    [Header(PBS)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Raymarching Settings)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _Fft("fft", Range(1, 100)) = 30
// @block Properties
    _Color2("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "DisableBatching" = "True"
}

Cull Back

CGINCLUDE



#define SPHERICAL_HARMONICS_PER_PIXEL


#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput SurfaceOutputStandard

#include "Assets/Raymarching/Shaders/Include/Common.cginc"
float _Fft;
// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
    float plane = Plane(pos, float3(0,1,0));
    float terrain = Terrain(pos);
   // float blend = AlphaBlendOp(plane, terrain, 0.4+0.6*sin(_Time.y*0.5)*0.5);
    float blend = AlphaBlendOp(plane, terrain,_Fft);
    return blend;
}
// @endblock

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
  // o.Emission = float4(ToLocal(ray.endPos).xy,1.0,1.0);
}
// @endblock

#include "Assets/Raymarching/Shaders/Include/Raymarching.cginc"

ENDCG

Pass
{
    Tags { "LightMode" = "Deferred" }

    Stencil
    {
        Comp Always
        Pass Replace
        Ref 128
    }

    CGPROGRAM
    #include "Assets/Raymarching/Shaders/Include/VertFragStandardObject.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_prepassfinal
    #pragma multi_compile OBJECT_SHAPE_CUBE OBJECT_SHAPE_SPHERE ___
    #pragma exclude_renderers nomrt
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ShadowCaster" }

    CGPROGRAM
    #include "Assets/Raymarching/Shaders/Include/VertFragShadowObject.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_shadowcaster
    #pragma multi_compile OBJECT_SHAPE_CUBE OBJECT_SHAPE_SPHERE ___
    #pragma fragmentoption ARB_precision_hint_fastest
    ENDCG
}

}

Fallback "Raymarching/Fallbacks/StandardSurfaceShader"

CustomEditor "Raymarching.MaterialEditor"

}