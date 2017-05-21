Shader "Raymarching/SpiralWave"
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

CGINCLUDE

#define WORLD_SPACE


#define CAMERA_INSIDE_OBJECT

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput GBufferOut

#include "Assets/Raymarching/Shaders/Include/Common.cginc"
float4 _Color2;
// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
   float d = pos.y+1.0;
  
   d = min (d, - pos.y+1.0);
   d = min(d,cos(pos.x)+cos(pos.y)+cos(pos.z)+cos(pos.y*0.2)*1.0);
   pos.x +=2.0;
   pos.x = myMod(pos.x,4.0)-2.0;

   d = min(d, Spiral(pos, 0.0));
   d = min(d, Spiral(pos, 4.0));
   d = min(d, Spiral(pos, 8.0));
  _Color2 = float4(Spiral(pos, 8.0),Spiral(pos, 0.0), Spiral(pos, 0.0), 1.0);

  return d;
}
// @endblock

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
 float4 toLoc = (ToWorld(ray.endPos),1.0);
 o.emission = float4(toLoc)-_Color2;
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

Fallback "Diffuse"

CustomEditor "Raymarching.MaterialEditor"

}