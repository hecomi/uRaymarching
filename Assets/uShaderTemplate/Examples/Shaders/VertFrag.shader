Shader "Custom/VertFrag"
{

Properties
{
// @block Properties
_MainTex("Texture", 2D) = "white" {}
// @endblock
}

SubShader
{

Tags { "Queue"="Geometry" "RenderType"="Opaque" }
LOD 100

CGINCLUDE

#include "UnityCG.cginc"

struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
};

// @block VertexShader
sampler2D _MainTex;
float4 _MainTex_ST;
v2f vert(appdata_full v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
    // UNITY_TRANSFER_FOG(o,o.vertex);
    return o;
}
// @endblock

// @block FragmentShader
fixed4 frag(v2f i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}
// @endblock

ENDCG

Pass
{
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #pragma multi_compile_fog
    ENDCG
}

}

CustomEditor "uShaderTemplate.MaterialEditor"

}
