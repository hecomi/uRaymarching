#ifndef URAYMARCHING_FORWARD_UNLIT_HLSL
#define URAYMARCHING_FORWARD_UNLIT_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "./Primitives.hlsl"
#include "./Raymarching.hlsl"

int _Loop;
float _MinDistance;
float4 _Color;

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 positionSS : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
    half4 fogFactorAndVertexLight : TEXCOORD4; // x: fogFactor, yzw: vertex light
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
    output.positionWS = vertexInput.positionWS;
    output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
    output.positionSS.z = -TransformWorldToView(output.positionWS).z;
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);

    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
    half fogFactor = ComputeFogFactor(output.positionCS.z);
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    return output;
}

FragOutput Frag(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, input, _Loop, _MinDistance);
    Raymarch(ray);

    InputData inputData = (InputData)0;
    inputData.positionWS = ray.endPos;
    inputData.normalWS = DecodeNormalWS(ray.normal);
    inputData.viewDirectionWS = SafeNormalize(GetCameraPosition() - ray.endPos);
    inputData.shadowCoord = TransformWorldToShadowCoord(ray.endPos);
    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
    #if SHADOWS_SCREEN
    float4 positionCS = TransformWorldToHClip(ray.endPos);
    inputData.shadowCoord = ComputeScreenPos(positionCS);
    #else
    inputData.shadowCoord = TransformWorldToShadowCoord(ray.endPos);
    #endif
#endif

    SurfaceData surfaceData = (SurfaceData)0;;
    InitializeStandardLitSurfaceData(float2(0, 0), surfaceData);

#ifdef POST_EFFECT
    POST_EFFECT(ray, surfaceData);
#endif

    half4 color = UniversalFragmentPBR(
        inputData, 
        surfaceData.albedo, 
        surfaceData.metallic, 
        surfaceData.specular, 
        surfaceData.smoothness, 
        surfaceData.occlusion, 
        surfaceData.emission, 
        surfaceData.alpha);

    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    FragOutput o;
    o.color = color;
    o.depth = ray.depth;

    return o;
}

#endif