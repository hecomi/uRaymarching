/**
\author Michael Mara and Morgan McGuire, Casual Effects. 2015.
*/
Shader "Hidden/ScreenSpaceReflection" 
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	
	
	CGINCLUDE

	#include "UnityCG.cginc"
	#include "UnityPBSLighting.cginc"
	#include "UnityStandardBRDF.cginc"
	#include "UnityStandardUtils.cginc"
	#include "ScreenSpaceRaytrace.cginc"
	
	float4 	 _ProjInfo;
	float4x4 _WorldToCameraMatrix;
	float4x4 _CameraToWorldMatrix;
	float4x4 _ProjectToPixelMatrix;
	float2   _ScreenSize;
    float2   _ReflectionBufferSize;
	float2	 _InvScreenSize;
	float3   _CameraClipInfo;

	sampler2D _CameraGBufferTexture0;
	sampler2D _CameraGBufferTexture1;
	sampler2D _CameraGBufferTexture2;
	sampler2D _CameraGBufferTexture3;
	sampler2D _CameraReflectionsTexture;
	
	float _CurrentMipLevel;
	float _RayStepSize;
	float _MaxRayTraceDistance;
	float _LayerThickness;
    float _FresnelFade;
    float _FresnelFadePower;
	
	
	sampler2D _MainTex;

	int _VisualizeWhereBilateral;
	int _EnableSSR;
	int _DebugMode;
    int _HalfResolution;
    int _TreatBackfaceHitAsMiss;
    int _SuppressBackwardsRays;
    int _TraceEverywhere;


    // RG: SS Hitpoint of ray
    // B: distance ray travelled, used for mip-selection in the final resolve
    // A: confidence value
    sampler2D _HitPointTexture;
	sampler2D _FinalReflectionTexture;

    // RGB: camera-space normal (encoded in [0-1])
    // A: Roughness
    sampler2D _NormalAndRoughnessTexture;

	float4 _MainTex_TexelSize;
	float4 _SourceToTempUV;
	
	int _EnableRefine;
	int _AdditiveReflection;
	int _ImproveCorners;
	
	float _ScreenEdgeFading;
	
	float _MipBias;
	
	int _UseOcclusion;
	
	int _MaxSteps;
	
	int _FullResolutionFiltering;
	
	int _BilateralUpsampling;
	
	float _MaxRoughness;
    float _RoughnessFalloffRange;
    float _SSRMultiplier;

    float _FadeDistance;

    float _DistanceBlur;

    int _FallbackToSky;
    int _UseEdgeDetector;
    int _HighlightSuppression;

    /** The height in pixels of a 1m object if viewed from 1m away. */
    float _PixelsPerMeterAtOneMeter;

    int         _UseAverageRayDistance;
    sampler2D   _AverageRayDistanceBuffer;

    // For temporal filtering:
    float4x4    _CurrentCameraToPreviousCamera;
    sampler2D   _PreviousReflectionTexture;
    sampler2D   _PreviousCSZBuffer;
    float       _TemporalAlpha;
    int         _UseTemporalConfidence;

	struct v2f 
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv2 : TEXCOORD1;
	};

	v2f vert( appdata_img v )
	{
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.texcoord.xy;
		o.uv2 = v.texcoord.xy;
		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv2.y = 1-o.uv2.y;
		#endif				
		return o;
	}

    float2 mipToSize(int mip) {
        return floor(_ReflectionBufferSize * exp2(-mip));
    }

	float3 ReconstructCSPosition(float2 S, float z) 
	{
		float linEyeZ = -LinearEyeDepth(z);
		return float3(( (( S.xy * _MainTex_TexelSize.zw) ) * _ProjInfo.xy + _ProjInfo.zw) * linEyeZ, linEyeZ);
	}

	/** Read the camera-space position of the point at screen-space pixel ssP */
	float3 GetPosition(float2 ssP) {
		float3 P;

		P.z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, ssP.xy);

		// Offset to pixel center
		P = ReconstructCSPosition(float2(ssP) /*+ float2(0.5, 0.5)*/, P.z);
		return P;
	}

	float square(float x) 
	{
		return x*x;
	}
	
	float applyVignette(float2 tsP, float vignetteSize, float vignetteStrength) {
		float vignette = pow(max(16.0 * tsP.x * tsP.y * (1.0 - tsP.x) * (1.0 - tsP.y), 0.0), 3.0 * vignetteSize);
	    return lerp(1.0, vignette, vignetteStrength);
	}
	
    float3 csMirrorVector(float3 csPosition, float3 csN) {
        float3 csE = -normalize(csPosition.xyz);
        float cos_o = dot(csN, csE);
        float3 c_mi = normalize((csN * (2.0 * cos_o)) - csE);
        return c_mi;
    }

	float4 fragRaytrace(v2f i, int stepRate)
	{
		float2 ssP = i.uv2.xy * _SourceToTempUV.zw;
		float3 csPosition = GetPosition(ssP);
        float smoothness = tex2D(_CameraGBufferTexture1, ssP).a;
		if (csPosition.z < -100.0 || smoothness == 0.0) {
			return float4(0.0,0.0,0.0,0.0);
		}

        if ((!_TraceEverywhere) && (smoothness < (1.0 - _MaxRoughness)) ) {
            return float4(0.0, 0.0, 0.0, 0.0);
        }
        
		float3 wsNormal = tex2D(_CameraGBufferTexture2, ssP).rgb * 2.0 - 1.0;
		
		int2 ssC = int2(ssP * _ScreenSize);

        float3 csN = mul((float3x3)(_WorldToCameraMatrix), wsNormal);
        float3 csRayDirection = csMirrorVector(csPosition, csN);

        if (_SuppressBackwardsRays > 0 && csRayDirection.z > 0.0) {
            return float4(0.0, 0.0, 0.0, 0.0);
        }

        float maxRayTraceDistance = _MaxRayTraceDistance;
        float jitterFraction = 0.0f;
        float layerThickness = _LayerThickness;

        int maxSteps = _MaxSteps;
        // Bump the ray more in world space as it gets farther away (and so each pixel covers more WS distance)
        float rayBump = max(-0.01*csPosition.z, 0.001);
        float2 hitPixel;
        float3 csHitPoint;
        float stepCount;
        
        bool wasHit = castDenseScreenSpaceRay
                   (csPosition + (csN) * rayBump, 
                    csRayDirection,
                    _ProjectToPixelMatrix,
                    _ScreenSize,
                    _CameraClipInfo,
                    jitterFraction,
                    maxSteps,
                    layerThickness,
                    maxRayTraceDistance,
                    hitPixel,
                    stepRate,
                    _EnableRefine == 1,
	                csHitPoint,
	                stepCount);
	                
		float2 tsPResult = hitPixel / _ScreenSize;
        float rayDist = dot(csHitPoint - csPosition, csRayDirection);
        float confidence = 0.0;
		if (wasHit) {
            confidence = square(1.0 - max(2.0*float(stepCount) / float(maxSteps) - 1.0, 0.0));
            confidence *= clamp(((_MaxRayTraceDistance - rayDist) / _FadeDistance), 0.0, 1.0);
            // Fake fresnel fade
            float3 csE = -normalize(csPosition.xyz);
            confidence *= max(0.0, lerp(pow(abs(dot(csRayDirection, -csE)), _FresnelFadePower), 1, 1.0 - _FresnelFade));
            if (_TreatBackfaceHitAsMiss > 0) {
                float3 wsHitNormal = tex2Dlod(_CameraGBufferTexture2, float4(tsPResult, 0, 0)).rgb * 2.0 - 1.0;
                float3 wsRayDirection = mul(_CameraToWorldMatrix, float4(csRayDirection, 0)).xyz;
                if (dot(wsHitNormal, wsRayDirection) > 0) {
                    confidence = 0.0;
                }
            }
        } else if (_FallbackToSky > 0) {
            float sceneZ = tex2Dlod(_CameraDepthTexture, float4(tsPResult, 0, 0)).r;
            sceneZ = -LinearEyeDepth(sceneZ);
            if (sceneZ < -1000) { // 1km ~= infinity
                confidence = 1.0;
            }
        }
		
		// Fade out reflections that hit near edge of screen, to prevent abrupt appearance/disappearance when object go off screen
		float vignetteStrength = _ScreenEdgeFading;
		float vignetteSize = 0.05;
		float vignette = applyVignette(tsPResult, vignetteSize, vignetteStrength);
		confidence *= vignette;


		return float4(tsPResult, rayDist, confidence);
	}
	
	float4 fragComposite(v2f i) : SV_Target
	{
		// Pixel being shaded 
		float2 tsP = i.uv2.xy;

		// View space point being shaded
		float3 C = GetPosition(tsP);

        // Final image before this pass
		float4 gbuffer3 = tex2D(_MainTex, i.uv);
		
		float4 specEmission = float4(0.0,0.0,0.0,0.0);
		float3 specColor = tex2D(_CameraGBufferTexture1, tsP).rgb;

		float roughness = 1.0-tex2D(_CameraGBufferTexture1, tsP).a;
		
		float4 reflectionTexel = tex2D(_FinalReflectionTexture, tsP * _SourceToTempUV.xy);
		
		float4 gbuffer0 = tex2D(_CameraGBufferTexture0, tsP);
		// Let core Unity functions do the dirty work of applying the BRDF
		float3 baseColor = gbuffer0.rgb;
		float occlusion = gbuffer0.a;
		float oneMinusReflectivity;
		baseColor = EnergyConservationBetweenDiffuseAndSpecular(baseColor, specColor, oneMinusReflectivity);
		
		float3 wsNormal = tex2D(_CameraGBufferTexture2, tsP).rgb * 2.0 - 1.0;

		float3 csEyeVec = normalize(C);
        float3 eyeVec = mul(_CameraToWorldMatrix, float4(csEyeVec, 0)).xyz;
		
		float3 worldPos =  mul(_CameraToWorldMatrix, float4(C, 1)).xyz;

        float cos_o = dot(wsNormal, eyeVec);
        float3 w_mi = -normalize((wsNormal * (2.0 * cos_o)) - eyeVec);
        

		float3 incomingRadiance = reflectionTexel.rgb;
		
		UnityLight light;
		light.color = 0;
		light.dir = 0;
		light.ndotl = 0;

		UnityIndirect ind;
		ind.diffuse = 0;
		ind.specular = incomingRadiance;
		
		float3 ssrResult = UNITY_BRDF_PBS (0, specColor, oneMinusReflectivity, 1-roughness, wsNormal, -eyeVec, light, ind).rgb * _SSRMultiplier;
		float confidence = reflectionTexel.a;
		
		if(_EnableSSR == 0) {
			confidence = 0.0;
		}

		specEmission.rgb = tex2D(_CameraReflectionsTexture, tsP).rgb;
		float3 finalGlossyTerm;
		// Subtract out Unity's glossy result: (we're just applying the delta)
		if (_AdditiveReflection == 0) {
			gbuffer3 -= specEmission;
			// We may have blown out our dynamic range by adding then subtracting the reflection probes.
			// As a half-measure to fix this, simply clamp to zero
			gbuffer3 = max(gbuffer3, 0);
			finalGlossyTerm = lerp(specEmission.rgb, ssrResult, saturate(confidence));
		} else {
			finalGlossyTerm = ssrResult*saturate(confidence);
		}
		if (_UseOcclusion) {
			finalGlossyTerm *= occlusion;
		}
		
		if (_DebugMode == 1)
			return float4(incomingRadiance,0);
		if (_DebugMode == 2)
			return float4(ssrResult,0);
		if (_DebugMode == 3)
			return float4(finalGlossyTerm,0);
		if (_DebugMode == 4)
			return confidence;
		if (_DebugMode == 5)
			return roughness;
		if (_DebugMode == 6)
			return float4(baseColor,0);
		if (_DebugMode == 7)
			return float4(specColor,0);
		if (_DebugMode == 8)
			return 1.0-oneMinusReflectivity;
		if (_DebugMode == 9)
			return float4(specEmission.rgb,0);
		if (_DebugMode == 10)
			return float4(specEmission.rgb-ssrResult,0);
		if (_DebugMode == 11)
			return float4(ssrResult-specEmission.rgb,0);
		if (_DebugMode == 12)
			return gbuffer3;
		if (_DebugMode == 13)
			return -float4(gbuffer3.rgb, 0.0);
        if (_DebugMode == 14) // Mip level, stored directly in ssrResult
            return float4(incomingRadiance, 0);
		
		// Additively blend the glossy GI result with the output buffer
		return gbuffer3 + float4(finalGlossyTerm, 0);
	}
	
	float roughnessWeight(float midpointRoughness, float tapRoughness) {
		return (1.0 - sqrt(sqrt(abs(midpointRoughness-tapRoughness))));
	}
	
	float normalWeight(float3 midpointNormal, float3 tapNormal) {
		return clamp(dot(midpointNormal, tapNormal), 0, 1);
	}
	
    float highlightDecompression(float x) {
        return x / (1.0 - x);
    }

    float3 highlightDecompression(float3 x) {
        return float3(
            highlightDecompression(x.x),
            highlightDecompression(x.y),
            highlightDecompression(x.z));
    }

    float highlightCompression(float x) {
        return x / (1.0 + x);
    }

    float3 highlightCompression(float3 x) {
        return float3(
            highlightCompression(x.x),
            highlightCompression(x.y),
            highlightCompression(x.z));
    }
	
	float4 _Axis;
	float4 fragGBlur(v2f i) : SV_Target
	{
		int radius = 4;
		// Pixel being shaded 
		float2 tsP = i.uv2.xy;
		float weightSum = 0.0;
		float gaussWeights[5] = {0.225, 0.150, 0.110, 0.075, 0.0525};//{0.225, 0.150, 0.110, 0.075, 0.0525};
		float4 resultSum = float4(0.0, 0.0, 0.0, 0.0);
        float4 unweightedResultSum = float4(0.0, 0.0, 0.0, 0.0);
        float4 nAndRough = tex2D(_NormalAndRoughnessTexture, tsP);
		float midpointRoughness = nAndRough.a;
		float3 midpointNormal = nAndRough.rgb * 2 - 1;
		if (_FullResolutionFiltering) {
			for (int i = -2*radius; i <= 2*radius; ++i) {
				float4 temp;
				float tapRoughness = midpointRoughness;
				float3 tapNormal = midpointNormal;
				float2 tsTap = tsP + (_Axis.xy * _MainTex_TexelSize.xy * float2(i,i));
				
				temp = tex2D(_MainTex, tsTap);

				int gaussWeightIndex;
				#if defined(UNITY_COMPILER_HLSL) && !defined(SHADER_API_D3D9)
				gaussWeightIndex = abs(i) >> 1; // We purposefully do integer division, but that does not compile on hlsl2glsl
				#else
				gaussWeightIndex = frac(abs(i) / 2);
				#endif
				
				float weight = temp.a * gaussWeights[gaussWeightIndex]*0.5;
				// Bilateral filtering
                if (_ImproveCorners) {
                    nAndRough = tex2D(_NormalAndRoughnessTexture, tsTap);
                    tapRoughness = nAndRough.a;
                    tapNormal = nAndRough.rgb * 2 - 1;
					weight *= normalWeight(midpointNormal, tapNormal);
				}
				weightSum += weight;
				resultSum += temp*weight;
                unweightedResultSum += temp;
			}
		} else {
			for (int i = -radius; i <= radius; ++i) {
				float4 temp;
				float tapRoughness;
				float3 tapNormal;
				float2 tsTap = tsP + (_Axis.xy * _MainTex_TexelSize.xy * float2(i,i)*2.0);
				
                temp = tex2D(_MainTex, tsTap);
                    
				float weight = temp.a * gaussWeights[abs(i)];
				// Bilateral filtering 
                if (_ImproveCorners) {
                    nAndRough = tex2D(_NormalAndRoughnessTexture, tsTap);
                    tapRoughness = nAndRough.a;
                    tapNormal = nAndRough.rgb * 2 - 1;
					weight *= normalWeight(midpointNormal, tapNormal);
				}
				weightSum += weight;
                if (_HighlightSuppression) {
                    temp.rgb = highlightCompression(temp.rgb);
                }
                unweightedResultSum += temp;
				resultSum += temp*weight;
			}
		}
		
        if (weightSum > 0.01) {
		    float invWeightSum = (1.0/weightSum);
		    // Adding the sqrt seems to decrease temporal flickering at the expense 
		    // of having larger "halos" of fallback on rough surfaces
		    // Subject to change with testing. Sqrt around only half the expression is *intentional*.
		    float confidence = min(resultSum.a * sqrt(max(invWeightSum, 2.0)), 1.0);
            float3 finalColor = resultSum.rgb * invWeightSum;
            if (_HighlightSuppression) {
                finalColor = highlightDecompression(finalColor);
            }
		    return float4(finalColor, confidence);
        } else {
            float3 finalColor = unweightedResultSum.rgb / (2 * radius + 1);
            if (_HighlightSuppression) {
                finalColor = highlightDecompression(finalColor);
            }
            return float4(finalColor, 0.0);
        }
	}
	
	sampler2D _ReflectionTexture0;
	sampler2D _ReflectionTexture1;
	sampler2D _ReflectionTexture2;
	sampler2D _ReflectionTexture3;
	sampler2D _ReflectionTexture4;
	// Simulate mip maps, since we don't have NPOT mip-chains
	float4 getReflectionValue(float2 tsP, int mip) {
		float4 coord = float4(tsP,0,0);
		if (mip == 0) {
			return tex2Dlod(_ReflectionTexture0, coord);
		} else if (mip == 1) {
			return tex2Dlod(_ReflectionTexture1, coord);
		} else if (mip == 2) {
			return tex2Dlod(_ReflectionTexture2, coord);
		} else if (mip == 3) {
			return tex2Dlod(_ReflectionTexture3, coord);
		} else {
			return tex2Dlod(_ReflectionTexture4, coord);
		}
	}

	sampler2D _EdgeTexture0;
	sampler2D _EdgeTexture1;
	sampler2D _EdgeTexture2;
	sampler2D _EdgeTexture3;
	sampler2D _EdgeTexture4;
    // Simulate mip maps, since we don't have NPOT mip-chains
	float4 getEdgeValue(float2 tsP, int mip) {
		float4 coord = float4(tsP + float2(1.0/(2 * mipToSize(mip))),0,0);
		if (mip == 0) {
			return tex2Dlod(_EdgeTexture0, coord);
		} else if (mip == 1) {
			return tex2Dlod(_EdgeTexture1, coord);
		} else if (mip == 2) {
			return tex2Dlod(_EdgeTexture2, coord);
		} else if (mip == 3) {
			return tex2Dlod(_EdgeTexture3, coord);
		} else {
			return tex2Dlod(_EdgeTexture4, coord);
		}
	}
	
	float2 centerPixel(float2 inputP) {
		return floor(inputP - float2(0.5,0.5)) + float2(0.5,0.5);
	}
	
	float2 snapToTexelCenter(float2 inputP, float2 texSize, float2 texSizeInv) {
		return centerPixel(inputP * texSize) * texSizeInv;
	}
	
	float4 bilateralUpsampleReflection(float2 tsP, int mip) {
		
		float2 smallTexSize = mipToSize(mip);
		float2 smallPixelPos = tsP * smallTexSize;
		float2 smallPixelPosi = centerPixel(smallPixelPos);
		float2 smallTexSizeInv = 1.0 / smallTexSize;
		
		
		float2 p0 = smallPixelPosi * smallTexSizeInv;
		float2 p3 = (smallPixelPosi + float2(1.0, 1.0)) * smallTexSizeInv;
		float2 p1 = float2(p3.x, p0.y);
		float2 p2 = float2(p0.x, p3.y);
		
		float4 V0 = getReflectionValue(p0.xy, mip);
		float4 V1 = getReflectionValue(p1.xy, mip);
		float4 V2 = getReflectionValue(p2.xy, mip);
		float4 V3 = getReflectionValue(p3.xy, mip);
		
		float a0 = 1.0;
	    float a1 = 1.0;
	    float a2 = 1.0;
	    float a3 = 1.0;

	    // Bilateral weights:
	    // Bilinear interpolation (filter distance)
	    float2  smallPixelPosf  = smallPixelPos - smallPixelPosi;
	    a0 = (1.0 - smallPixelPosf.x) * (1.0 - smallPixelPosf.y);
	    a1 = smallPixelPosf.x * (1.0 - smallPixelPosf.y);
	    a2 = (1.0 - smallPixelPosf.x) * smallPixelPosf.y;
	    a3 = smallPixelPosf.x * smallPixelPosf.y;
		
		float2 fullTexSize = _ReflectionBufferSize;
		float2 fullTexSizeInv = 1.0 / fullTexSize;
		
		float4 hiP0 = float4(snapToTexelCenter(p0, fullTexSize, fullTexSizeInv), 0,0);
		float4 hiP3 = float4(snapToTexelCenter(p3, fullTexSize, fullTexSizeInv), 0,0);
		float4 hiP1 = float4(snapToTexelCenter(p1, fullTexSize, fullTexSizeInv), 0,0);
		float4 hiP2 = float4(snapToTexelCenter(p2, fullTexSize, fullTexSizeInv), 0,0);
	    
        float4 tempCenter = tex2Dlod(_NormalAndRoughnessTexture, float4(tsP, 0, 0));
	    float3 n  = tempCenter.xyz * 2 - 1;

        float4 temp0 = tex2Dlod(_NormalAndRoughnessTexture, hiP0);
        float4 temp1 = tex2Dlod(_NormalAndRoughnessTexture, hiP1);
        float4 temp2 = tex2Dlod(_NormalAndRoughnessTexture, hiP2);
        float4 temp3 = tex2Dlod(_NormalAndRoughnessTexture, hiP3);

	    float3 n0 = temp0.xyz * 2 - 1;
        float3 n1 = temp1.xyz * 2 - 1;
        float3 n2 = temp2.xyz * 2 - 1;
        float3 n3 = temp3.xyz * 2 - 1;
	
	    a0 *= normalWeight(n, n0);
	    a1 *= normalWeight(n, n1);
	    a2 *= normalWeight(n, n2);
	    a3 *= normalWeight(n, n3);
	    
	    float r = tempCenter.a;
	    float r0 = temp0.a;
	    float r1 = temp1.a;
	    float r2 = temp2.a;
	    float r3 = temp3.a;
	    
	    
	    a0 *= roughnessWeight(r, r0);
	    a1 *= roughnessWeight(r, r1);
	    a2 *= roughnessWeight(r, r2);
	    a3 *= roughnessWeight(r, r3);

        // Slightly offset from zero
        a0 = max(a0, 0.001);
        a1 = max(a1, 0.001);
        a2 = max(a2, 0.001);
        a3 = max(a3, 0.001);
	    
	    // Nearest neighbor
	    // a0 = a1 = a2 = a3 = 1.0;

	    // Normalize the blending weights (weights were chosen so that 
	    // the denominator can never be zero)
	    float norm = 1.0 / (a0 + a1 + a2 + a3);
	        
	    // Blend
	    float4 value = (V0 * a0 + V1 * a1 + V2 * a2 + V3 * a3) * norm;
        //return V0;
        return value;
	}

    /** Explicit bilinear fetches; must be used if the reflection buffer is bound using point sampling */
    float4 bilinearUpsampleReflection(float2 tsP, int mip) {

        float2 smallTexSize = mipToSize(mip);
        float2 smallPixelPos = tsP * smallTexSize;
        float2 smallPixelPosi = centerPixel(smallPixelPos);
        float2 smallTexSizeInv = 1.0 / smallTexSize;


        float2 p0 = smallPixelPosi * smallTexSizeInv;
        float2 p3 = (smallPixelPosi + float2(1.0, 1.0)) * smallTexSizeInv;
        float2 p1 = float2(p3.x, p0.y);
        float2 p2 = float2(p0.x, p3.y);

        float4 V0 = getReflectionValue(p0.xy, mip);
        float4 V1 = getReflectionValue(p1.xy, mip);
        float4 V2 = getReflectionValue(p2.xy, mip);
        float4 V3 = getReflectionValue(p3.xy, mip);

        float a0 = 1.0;
        float a1 = 1.0;
        float a2 = 1.0;
        float a3 = 1.0;

        // Bilateral weights:
        // Bilinear interpolation (filter distance)
        float2  smallPixelPosf = smallPixelPos - smallPixelPosi;
        a0 = (1.0 - smallPixelPosf.x) * (1.0 - smallPixelPosf.y);
        a1 = smallPixelPosf.x * (1.0 - smallPixelPosf.y);
        a2 = (1.0 - smallPixelPosf.x) * smallPixelPosf.y;
        a3 = smallPixelPosf.x * smallPixelPosf.y;

        // Blend
        float4 value = (V0 * a0 + V1 * a1 + V2 * a2 + V3 * a3);
        return value;
    }

    // Unity's roughness is GGX roughness squared
    float roughnessToBlinnPhongExponent(float roughness) {
        float r2 = roughness*roughness;
        return 2.0f / r2*r2 - 2.0f;
    }

    float glossyLobeSlope(float roughness) {
        return pow(roughness, 4.0/3.0);
    }


    // Empirically based on our filter:
    //   Mip   | Pixels
    //  --------------
    //    0    |   1          no filter, so single pixel
    //    1    |   17         2r + 1 filter applied once, grabbing from pixels r away in either direction (r=8, four samples times stride of 2)
    //    2    |   50         2r + 1 filter applied on double size pixels, and each of those pixels had reached another r out to the side 2(2r + 1) + m_1           
    //    3    |   118        4(2r + 1) + m_2
    //    4    |   254        8(2r + 1) + m_3
    //
    // Approximated by pixels = 16*2^mip-15
    // rearranging we get mip = log_2((pixels + 15) / 16) 
    //
    float filterFootprintInPixelsToMip(float footprint) {
        return log2((footprint + 15) / 16);
    }
	
    float3 ansiGradient(float t) {
        //return float3(t, t, t);
        return fmod(floor(t * float3(8.0, 4.0, 2.0)), 2.0);
    }

	float4 fragCompositeSSR(v2f i) : SV_Target
	{
		// Pixel being shaded 
		float2 tsP = i.uv2.xy;

		float roughness = 1.0-tex2D(_CameraGBufferTexture1, tsP * _SourceToTempUV.zw).a;

        float rayDistance = 0.0;
        if (_UseAverageRayDistance) {
            rayDistance = tex2D(_AverageRayDistanceBuffer, tsP).r;
        } else {
            rayDistance = tex2D(_HitPointTexture, tsP).z;
        }

        // Get the camera space position of the reflection hit
        float3 csPosition = GetPosition(tsP);
        float3 wsNormal = tex2D(_CameraGBufferTexture2, tsP).rgb * 2.0 - 1.0;
        float3 csN = mul((float3x3)(_WorldToCameraMatrix), wsNormal);
        float3 c_mi = csMirrorVector(csPosition, csN);
        float3 csHitpoint = c_mi * rayDistance + csPosition;


        float gatherFootprintInMeters = glossyLobeSlope(roughness) * rayDistance;
        // We could add a term that incorporates the normal
        // This approximation assumes reflections happen at a glancing angle
        float filterFootprintInPixels = gatherFootprintInMeters * _PixelsPerMeterAtOneMeter / csHitpoint.z;
        if (_HalfResolution == 1) {
            filterFootprintInPixels *= 0.5;
        }

        float mip = filterFootprintInPixelsToMip(filterFootprintInPixels);

        float nonPhysicalMip = pow(roughness, 3.0 / 4.0) * UNITY_SPECCUBE_LOD_STEPS;

        if (_HalfResolution == 1) {
            nonPhysicalMip = nonPhysicalMip * 0.7;
        }
        mip = lerp(nonPhysicalMip, mip, _DistanceBlur);

        if (_DebugMode == 14) {
            return float4(ansiGradient(mip*0.25), 1.0);
        }

		mip = max(0, min(4, mip+_MipBias));
		
		float4 result;
		{
			int mipMin = int(mip);
			int mipMax = min(mipMin + 1, 4);
			float mipLerp = mip-mipMin;

            if (_BilateralUpsampling == 1) {
                if (_UseEdgeDetector == 1) {
                    float nonEdginess = lerp(getEdgeValue(tsP, mipMin),
                        getEdgeValue(tsP, mipMax), mipLerp);
                    if (nonEdginess < 0.9) {
                        result = lerp(bilateralUpsampleReflection(tsP, mipMin), bilateralUpsampleReflection(tsP, mipMax), mipLerp);
                        if (_VisualizeWhereBilateral == 1) {
                            result = float4(1, 0, 0, 0);
                        }
                    } else {
                        result = lerp(bilinearUpsampleReflection(tsP, mipMin), bilinearUpsampleReflection(tsP, mipMax), mipLerp);
                    }
                } else {
                    result = lerp(bilateralUpsampleReflection(tsP, mipMin), bilateralUpsampleReflection(tsP, mipMax), mipLerp);
                }
            } else {
                float4 minResult = getReflectionValue(tsP, mipMin);
                float4 maxResult = getReflectionValue(tsP, mipMax);
                result = lerp(minResult, maxResult, mipLerp);
                result.a = min(minResult.a, maxResult.a);
            }
		}
		
        result.a = min(result.a, 1.0);
		float vignetteStrength = _ScreenEdgeFading;
		float vignetteSize = 0.05;
		float vignette = applyVignette(tsP, vignetteSize, vignetteStrength);
		result.a *= vignette;

        
        float alphaModifier = 1.0 - clamp((roughness - (_MaxRoughness - _RoughnessFalloffRange)) / _RoughnessFalloffRange, 0.0, 1.0);
        result.a *= alphaModifier;
		return  result; 
	}
	
	float4 fragBlit(v2f i) : SV_Target
	{
		// Pixel being shaded 
		float2 ssP = i.uv2.xy;
		return tex2D(_MainTex, ssP);
		
	}
	
	float edgeDetector(float2 tsP, float2 axis, float2 texelSize) {
        float4 temp = tex2D(_NormalAndRoughnessTexture, tsP);
		float midpointRoughness = temp.a;
		float3 midpointNormal = temp.rgb * 2 - 1;

		float tapRoughness;
		float3 tapNormal;
		float2 tsTap = tsP + (axis * _MainTex_TexelSize.xy);
			
        temp = tex2D(_NormalAndRoughnessTexture, tsTap);
		tapRoughness = temp.a;
		tapNormal = temp.rgb * 2 - 1;
				
		float weight = 1.0;
        weight *= roughnessWeight(midpointRoughness, tapRoughness);
        weight *= normalWeight(midpointNormal, tapNormal);
		
		return weight;
	}
	
	
	float4 fragEdge(v2f i) : SV_Target
	{
		float2 tsP = i.uv2.xy;
		return edgeDetector(tsP, float2(1,0), _MainTex_TexelSize.xy) * edgeDetector(tsP, float2(0,1), _MainTex_TexelSize.xy);
	}
	
	int _LastMip;
	float4 fragMin(v2f i) : SV_Target
	{
		float2 tsP = i.uv2.xy;
		float2 lastTexSize = mipToSize(_LastMip);
		float2 lastTexSizeInv = 1.0 / lastTexSize;//_SourceToTempUV.xy * exp2(mip);
		float2 p00 = snapToTexelCenter(tsP, lastTexSize, lastTexSizeInv);
		float2 p11 = p00 + lastTexSizeInv;
		return min( 
				min(tex2D(_MainTex, p00), tex2D(_MainTex, p11)),
				min(tex2D(_MainTex, float2(p00.x, p11.y)), tex2D(_MainTex, float2(p11.x, p00.y)))
			);
	}

    float4 fragResolveHitPoints(v2f i) : SV_Target
    {
        float2 tsP = i.uv2.xy;
        float4 temp = tex2D(_HitPointTexture, tsP);
        float2 hitPoint = temp.xy;
        float confidence = temp.w;
        float3 colorResult = confidence > 0.0 ? 
            tex2D(_MainTex, hitPoint).rgb : 
            tex2D(_CameraReflectionsTexture, tsP).rgb;

        return float4(colorResult, confidence);
    }

    float4 fragBilatKeyPack(v2f i) : SV_Target
    {
        float2 tsP = i.uv2.xy;
        float3 csN = tex2D(_CameraGBufferTexture2, tsP).xyz;
        float roughness = tex2D(_CameraGBufferTexture1, tsP).a;
        return float4(csN, roughness);
    }

    float4 fragDepthToCSZ(v2f i) : SV_Target
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2.xy);
        return float4(-LinearEyeDepth(depth), 0.0, 0.0, 0.0);
    }
    
    
    float3 csPositionToOldNormalizedScreenCoordinate(float3 csPosition) 
    {
        // We could multiply these matrices together on the CPU
        float4 oldCSPosition = mul(_CurrentCameraToPreviousCamera, float4(csPosition, 1.0));
        float4 oldSSCoordinate = mul(_ProjectToPixelMatrix, oldCSPosition);
        return float3((oldSSCoordinate.xy / oldSSCoordinate.w) * _InvScreenSize, oldCSPosition.z);
    }

    float4 fragTemporalFilter(v2f i) : SV_Target
    {
        float2 tsP = i.uv2.xy;
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, tsP);
        float3 csPosition = GetPosition(tsP);

        float rayDistance = 0.0;
        if (_UseAverageRayDistance) {
            rayDistance = tex2D(_AverageRayDistanceBuffer, tsP).r;
        } else {
            rayDistance = tex2D(_HitPointTexture, tsP).b;
        }

        // Virtual is the physics sense, not the other 20+ interpretations in CG
        float3 virtualReflectionCSPosition = normalize(csPosition) * rayDistance + csPosition;

        float3 oldTSP = csPositionToOldNormalizedScreenCoordinate(csPosition);
        float3 oldVirtualReflectionTSP = csPositionToOldNormalizedScreenCoordinate(virtualReflectionCSPosition);

        float  oldCSZ = tex2D(_PreviousCSZBuffer, oldTSP.xy);
        float4 currentResult = tex2D(_FinalReflectionTexture, tsP);
        float4 oldResult = tex2D(_PreviousReflectionTexture, oldVirtualReflectionTSP.xy);

        float zError = abs(oldCSZ - oldTSP.z);
        // Start knocking down contribution at 5cm error, go to 0 at 5 more cm later
        float fallbackStart = 0.05;
        float fallbackEnd = 0.05;
        float zAlphaModifier = 1.0 - clamp((zError - fallbackStart) * (1.0 / fallbackEnd), 0.0, 1.0);

        float alpha = _TemporalAlpha;
        alpha *= zAlphaModifier;
        
        if (_UseTemporalConfidence) {
            alpha *= oldResult.w;
        }
        return lerp(currentResult, oldResult, alpha);

    }


    float4 fragAverageRayDistance(v2f i) : SV_Target
    {
        float2 tsP = i.uv2.xy;

        float sumRayDistance = tex2D(_HitPointTexture, tsP).b;
        float sumWeight = 1.0;

        float roughness = 1.0 - tex2D(_CameraGBufferTexture1, tsP).a;
        float step = roughness * 3.0;
        /*
        for (float x = -step; x < step; x += 2 * step) {
            for (float y = -step; y < step; y += 2 * step) {
                float weight = 0.5;
                sumRayDistance += weight * tex2D(_HitPointTexture, (float2(x,y) * _InvScreenSize) + tsP).b;
                sumWeight += weight;
            }
        }
        */
        return float4(sumRayDistance / sumWeight, 0.0, 0.0, 0.0);
    }

	ENDCG

SubShader {

	ZTest Always Cull Off ZWrite Off

	// 0: Raytrace, step size 1
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragRaytrace1
		#pragma target 3.0
		float4 fragRaytrace1(v2f i) : SV_Target { return fragRaytrace(i, 1); }
		ENDCG
	}

	// 1: Raytrace, step size 2
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragRaytrace2
		#pragma target 3.0
		float4 fragRaytrace2(v2f i) : SV_Target { return fragRaytrace(i, 2); }
		ENDCG
	}

	// 2: Raytrace, step size 4
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragRaytrace4
		#pragma target 3.0
		float4 fragRaytrace4(v2f i) : SV_Target { return fragRaytrace(i, 4); }
		ENDCG
	}

	// 3: Raytrace, step size 8
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragRaytrace8
		#pragma target 3.0
		float4 fragRaytrace8(v2f i) : SV_Target { return fragRaytrace(i, 8); }
		ENDCG
	}

	// 4: Raytrace, step size 16
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragRaytrace16
		#pragma target 3.0
		float4 fragRaytrace16(v2f i) : SV_Target { return fragRaytrace(i, 16); }
		ENDCG
	}
	
	// 5: Composite
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragComposite
		#pragma target 3.0
		ENDCG
	}
	
	// 6: GBlur
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragGBlur
		#pragma target 3.0
		ENDCG
	}
	
	// 7: CompositeSSR
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragCompositeSSR
		#pragma target 3.0
		ENDCG
	}
	
	// 8: Simple Blit
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragBlit
		#pragma target 3.0
		ENDCG
	}
	
	// 9: Generate Edge Texture
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragEdge
		#pragma target 3.0
		ENDCG
	}
	
	// 10: Min mip generation
	Pass {
		CGPROGRAM
		#pragma exclude_renderers gles xbox360 ps3
		#pragma vertex vert
		#pragma fragment fragMin
		#pragma target 3.0
		ENDCG
	}

    // 11: Hit point texture to reflection buffer
    Pass {
        CGPROGRAM
        #pragma exclude_renderers gles xbox360 ps3
        #pragma vertex vert
        #pragma fragment fragResolveHitPoints
        #pragma target 3.0
        ENDCG
    }

    // 12: Pack Bilateral Filter Keys in single buffer
    Pass{
        CGPROGRAM
        #pragma exclude_renderers gles xbox360 ps3
        #pragma vertex vert
        #pragma fragment fragBilatKeyPack
        #pragma target 3.0
        ENDCG
    }

    // 13: Blit depth information as camera space Z
    Pass{
        CGPROGRAM
        #pragma exclude_renderers gles xbox360 ps3
        #pragma vertex vert
        #pragma fragment fragDepthToCSZ
        #pragma target 3.0
        ENDCG
    }

    // 14: Temporally filter buffer
    Pass{
        CGPROGRAM
        #pragma exclude_renderers gles xbox360 ps3
        #pragma vertex vert
        #pragma fragment fragTemporalFilter
        #pragma target 3.0
        ENDCG
    }

    // 15: Generate average ray distance
    Pass{
        CGPROGRAM
        #pragma exclude_renderers gles xbox360 ps3
        #pragma vertex vert
        #pragma fragment fragAverageRayDistance
        #pragma target 3.0
        ENDCG
    }

}

Fallback off

}
