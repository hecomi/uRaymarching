Shader "Raymarching/World"
{

Properties
{
    [Header(GBuffer)]
    _Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
    _Specular("Specular", Color) = (0.0, 0.0, 0.0, 0.0)
    _Emission("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

    [Header(Raymarching Settings)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01

// @block Properties
[Header(Additional Parameters)]
_Grid("Grid", 2D) = "" {}
    
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
float4 _Color;
// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
/// pos.yz = RotTwo(pos.yz, pos.x*sin(_Time.y)*0.05);
 // pos = Rotate(pos, pos.z*sin(_Time.y*0.1)*0.05,float3(0,0,-1));
  pos = Rotate(pos, pos.z*cos(_Time.y*0.02)*0.2,float3(0,0,-1));
  //pos = Rotate(pos, pos.z*sin(_Time.y*0.3)*0.01,float3(-1,0,0));
 // pos = Rotate(pos, pos.x*sin(_Time.y*0.3)*0.01,pos.y);
  pos = Repeat(pos, 1.0);
//pModPolar(p.xz,7); p -= vec3(10,0,0);
 //pos.xy = pModPolar(pos.xy, 3); pos -= float3(0,6,0);
 float box = Box(pos, 0.01);
 float sphere = Sphere (pos, 0.2);
// float cylinder = Cylinder (pos, 1.59);
 float cylinder2 = smin(fCylinder (pos, 0.02,1.2),box,0.8+0.44*cos(_Time.y*0.5));
   // pos = RotateY(pos,0.1+pos.z*cos(_Time.y)*0.01);

   //float tunnel = Tunnel(Repeat(pos, 2.0),sin(_Time.y)*0.5);
  //float d1 = RoundBox(Repeat(pos, float3(6, 6, 6)), 1 - r, r);
 //  float sphere2 = Repeat(sphere,0.0);
//   pos.xz = RotTwo(pos.xy,_Time.y);
  //  pos. xy = RotTwo (pos.zy , time/1.0);
   // pos. xz = RotTwo (pos.xz, time * 0.7);
  // smin(cylinder, sphere,0.9);
    return cylinder2;
}
// @endblock

// @block PostEffect
sampler2D _Grid;
float4 _Grid_ST;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    o.emission = float4(ToLocal(ray.depth).yx,0.9,1.0) * _Color;
   // o.emission = float4(_Color.xyz,1.0);
 //   o.emission = tex2D(_Grid, ray.endPos.xy *_Grid_ST.xy + _Grid_ST.zw);
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