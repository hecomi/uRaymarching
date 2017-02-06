Shader "Raymarching/Rings"
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
#define CAMERA_INSIDE_OBJECT

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput SurfaceOutputStandard

#include "Assets/Raymarching/Shaders/Include/Common.cginc"

// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
    float t = _Time.x/6.0;
    float a = 6 * PI * t;
    float s = pow(sin(a), 2.0);
    //return DiscRing(pos,0.9,0.1);
  float sphere = Sphere(pos, 5.5);
  float poly = Polyhedron(pos);
  float disc = DiscObjects(pos, _Time.y/8.0,0.2);
  float box = Box(pos,4.0);
  float2 tile = TileMove(pos.xz, t, 1.5, 9);
  float plane = Plane(pos, float3(0,1,0));
  
 float noise = SimplexNoise(pos);
  float blend = lerp(tile,sphere, s-0.1);
 float blender = lerp(noise,sphere, s-0.1);
  float blend2 = lerp(sphere,blender, s-0.1);
  float blend3 = lerp(disc,blender, s);
 
  return blend3;
}
// @endblock

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
   o.Albedo = float4(ToLocal(ray.endPos).xy,0.4,1.0);
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