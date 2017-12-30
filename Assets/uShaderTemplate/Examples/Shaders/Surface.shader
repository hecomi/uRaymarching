Shader "Custom/Surface"
{

Properties
{
    _Color("Color", Color) = (1,1,1,1)
    _MainTex("Albedo (RGB)", 2D) = "white" {}
    _NormalTex("Normalmap", 2D) = "bump" {}
    _DispTex("Disp Texture", 2D) = "gray" {}
    _Displacement("Displacement", Range(0, 1.0)) = 0.3
    _Tess("Tess Factor", Range(1, 32.0)) = 3
    _Glossiness("Smoothness", Range(0,1)) = 0.5
    _Metallic("Metallic", Range(0,1)) = 0.0
}

SubShader
{

Tags { "RenderType"="Opaque" }
LOD 300

CGPROGRAM

#pragma surface surf Standard addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap 

#pragma target 5.0

struct Input
{
    float2 uv_MainTex;
};

sampler2D _MainTex;
sampler2D _NormalTex;
half _Glossiness;
half _Metallic;
fixed4 _Color;

struct appdata
{
    float4 vertex   : POSITION;
    float4 tangent  : TANGENT;
    float3 normal   : NORMAL;
    float2 texcoord : TEXCOORD0;
};

float _Tess;
float _Displacement;
sampler2D _DispTex;

float4 tessFixed()
{
    return _Tess;
}

void disp(inout appdata v)
{
    float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
    v.vertex.xyz += v.normal * d;
}

void surf(Input IN, inout SurfaceOutputStandard o)
{
// @block SurfaceFunction
fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
o.Albedo = c.rgb;
o.Metallic = _Metallic;
o.Smoothness = _Glossiness;
o.Alpha = c.a;
o.Normal = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex));
// @endblock
}

ENDCG

}

FallBack "Diffuse"

CustomEditor "uShaderTemplate.MaterialEditor"

}
