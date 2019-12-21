#ifndef URAYMARCHING_FORWARD_UNLIT_HLSL
#define URAYMARCHING_FORWARD_UNLIT_HLSL

#include "./Primitives.hlsl"
#include "./Raymarching.hlsl"

int _Loop;
float _MinDistance;
float4 _Color;

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 positionSS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float fogCoord : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct FragOutput
{
    float4 color : SV_Target;
#ifdef USE_RAYMARCHING_DEPTH
    float depth : SV_Depth;
#endif
};

Varyings Vert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.fogCoord = ComputeFogFactor(output.positionCS.z);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
    output.positionSS.z = -TransformWorldToView(output.positionWS).z;

    return output;
}

FragOutput Frag(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, input, _Loop, _MinDistance);
    Raymarch(ray);

    FragOutput o;

    o.color = _Color;
#ifdef USE_RAYMARCHING_DEPTH
    o.depth = ray.depth;
#endif

    AlphaDiscard(o.color.a, _Cutoff);

#ifdef _ALPHAPREMULTIPLY_ON
    o.color.rgb *= o.color.a;
#endif

#ifdef POST_EFFECT
    POST_EFFECT(ray, o.color);
#endif

    o.color.rgb = MixFog(o.color.rgb, input.fogCoord);

    return o;
}

#endif