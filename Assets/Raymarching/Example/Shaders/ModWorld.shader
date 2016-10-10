Shader "Raymarching/ModWorld"
{

Properties
{
    [Header(GBuffer)]
    _Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
    _Specular("Specular", Color) = (0.0, 0.0, 0.0, 0.0)
    _Emission("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

    [Header(Raymarching Settings)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01


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
    "DisableBatching" = "True"
}

CGINCLUDE

#define WORLD_SPACE



#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput GBufferOut

#include "Assets/Raymarching/Shaders/Include/Common.cginc"

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
    o.emission = tex2D(_Grid, ray.endPos.xy * _Grid_ST.xy + _Grid_ST.zw);
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
    #include "Assets/Raymarching/Shaders/Include/VertFragDirectScreen.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_prepassfinal
    #pragma multi_compile OBJECT_SHAPE_CUBE OBJECT_SHAPE_SPHERE ___
    #pragma exclude_renderers nomrt
    ENDCG
}



}

Fallback Off

CustomEditor "Raymarching.MaterialEditor"

}