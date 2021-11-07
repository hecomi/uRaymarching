#ifndef URAYMARCHING_DEPTH_ONLY_HLSL
#define URAYMARCHING_DEPTH_ONLY_HLSL

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
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct FragOutput
{
    float4 color : SV_Target;
    float depth : SV_Depth;
};

Varyings Vert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;

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
    o.color = 0;
    o.depth = ray.depth;
    return o;
}

#endif