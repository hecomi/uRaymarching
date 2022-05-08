#ifndef URAYMARCHING_DEFERRED_LIT_HLSL
#define URAYMARCHING_DEFERRED_LIT_HLSL

#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
#include "./Primitives.hlsl"
#include "./Raymarching.hlsl"

int _Loop;
float _MinDistance;
float4 _Color;

struct Attributes
{
    float4 positionOS        : POSITION;
    float3 normalOS          : NORMAL;
    float4 tangentOS         : TANGENT;
    float2 texcoord          : TEXCOORD0;
    float2 staticLightmapUV  : TEXCOORD1;
    float2 dynamicLightmapUV : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS        : SV_POSITION;
    float4 positionSS        : TEXCOORD0;
    float3 positionWS        : TEXCOORD1; // xyz: posWS
    half3  normalWS          : TEXCOORD2; // xyz: normal, w: viewDir.x
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    half3 vertexLighting     : TEXCOORD3; // xyz: vertex light
#endif
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 4);
#ifdef DYNAMICLIGHTMAP_ON
    float2 dynamicLightmapUV : TEXCOORD5; // Dynamic lightmap UVs
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct CustomFragOutput
{
    half4 GBuffer0 : SV_Target0;
    half4 GBuffer1 : SV_Target1;
    half4 GBuffer2 : SV_Target2;
    half4 GBuffer3 : SV_Target3;
#ifdef GBUFFER_OPTIONAL_SLOT_1
    GBUFFER_OPTIONAL_SLOT_1_TYPE GBuffer4 : SV_Target4;
#endif
#ifdef GBUFFER_OPTIONAL_SLOT_2
    half4 GBuffer5 : SV_Target5;
#endif
#ifdef GBUFFER_OPTIONAL_SLOT_3
    half4 GBuffer6 : SV_Target6;
#endif
    float depth : SV_Depth;
};

Varyings Vert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput= GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
    output.positionSS.z = -TransformWorldToView(output.positionWS).z;
    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);

    OUTPUT_LIGHTMAP_UV(
        input.staticLightmapUV, 
        unity_LightmapST, 
        output.staticLightmapUV);

#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = 
        input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + 
        unity_DynamicLightmapST.zw;
#endif

    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        half3 vertexLight = VertexLighting(
            vertexInput.positionWS, 
            normalInput.normalWS);
        output.vertexLighting = vertexLight;
    #endif

    return output;
}

CustomFragOutput Frag(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, input, _Loop, _MinDistance);
    Raymarch(ray);

    InputData inputData = (InputData)0;
    inputData.positionWS = ray.endPos;
    inputData.positionCS = TransformWorldToHClip(ray.endPos);
    inputData.normalWS = NormalizeNormalPerPixel(DecodeNormalWS(ray.normal));
    inputData.viewDirectionWS = SafeNormalize(GetCameraPosition() - ray.endPos);
    inputData.shadowCoord = TransformWorldToShadowCoord(ray.endPos);

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        inputData.vertexLighting = input.vertexLighting.xyz;
    #else
        inputData.vertexLighting = half3(0, 0, 0);
    #endif

    inputData.fogCoord = 0;

#if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(
        input.staticLightmapUV, 
        input.dynamicLightmapUV, 
        input.vertexSH, 
        inputData.normalWS);
#else
    inputData.bakedGI = SAMPLE_GI(
        input.staticLightmapUV, 
        input.vertexSH, 
        inputData.normalWS);
#endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

#if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif
#endif

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(float2(0, 0), surfaceData);

#ifdef POST_EFFECT
    POST_EFFECT(ray, surfaceData);
#endif

#ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
#endif

    BRDFData brdfData;

    InitializeBRDFData(
        surfaceData.albedo, 
        surfaceData.metallic, 
        surfaceData.specular, 
        surfaceData.smoothness, 
        surfaceData.alpha, 
        brdfData);

    Light mainLight = GetMainLight(
        inputData.shadowCoord, 
        inputData.positionWS, 
        inputData.shadowMask);

    MixRealtimeAndBakedGI(
        mainLight, 
        inputData.normalWS, 
        inputData.bakedGI, 
        inputData.shadowMask);

    half3 color = GlobalIllumination(
        brdfData, 
        inputData.bakedGI, 
        surfaceData.occlusion, 
        inputData.positionWS, 
        inputData.normalWS, 
        inputData.viewDirectionWS);

    FragmentOutput baseOutput = BRDFDataToGbuffer(
        brdfData, 
        inputData, 
        surfaceData.smoothness,
        surfaceData.emission + color, 
        surfaceData.occlusion);

    CustomFragOutput output = (CustomFragOutput)0;
    output.GBuffer0 = baseOutput.GBuffer0;
    output.GBuffer1 = baseOutput.GBuffer1;
    output.GBuffer2 = baseOutput.GBuffer2;
    output.GBuffer3 = baseOutput.GBuffer3;
#ifdef GBUFFER_OPTIONAL_SLOT_1
    output.GBuffer4 = baseOutput.GBuffer4;
#endif
#ifdef GBUFFER_OPTIONAL_SLOT_2
    output.GBuffer5 = baseOutput.GBuffer5;
#endif
#ifdef GBUFFER_OPTIONAL_SLOT_3
    output.GBuffer6 = baseOutput.GBuffer6;
#endif
    output.depth = ray.depth + 1e-8;

    return output;
}

#endif