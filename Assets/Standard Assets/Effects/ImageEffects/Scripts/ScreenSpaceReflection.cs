using System;
using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    [AddComponentMenu("Image Effects/Rendering/Screen Space Reflection")]
    public class ScreenSpaceReflection : PostEffectsBase
    {
        public enum SSRDebugMode
        {
            None = 0,
            IncomingRadiance = 1,
            SSRResult = 2,
            FinalGlossyTerm = 3,
            SSRMask = 4,
            Roughness = 5,
            BaseColor = 6,
            SpecColor = 7,
            Reflectivity = 8,
            ReflectionProbeOnly = 9,
            ReflectionProbeMinusSSR = 10,
            SSRMinusReflectionProbe = 11,
            NoGlossy = 12,
            NegativeNoGlossy = 13,
            MipLevel = 14,
        }

        public enum SSRResolution
        {
            FullResolution = 0,
            HalfTraceFullResolve = 1,
            HalfResolution = 2,
        }

        [Serializable]
        public struct SSRSettings
        {
            [AttributeUsage(AttributeTargets.Field)]
            public class LayoutAttribute : Attribute
            {
                public enum Category
                {
                    Basic,
                    Reflections,
                    Advanced,
                    Debug,
                    Undefined
                }

                public readonly Category category;
                public readonly int priority;

                public LayoutAttribute(Category category, int priority)
                {
                    this.category = category;
                    this.priority = priority;
                }
            }
            
            /// BASIC SETTINGS
            [Tooltip("Nonphysical multiplier for the SSR reflections. 1.0 is physically based.")]
            [Range(0.0f, 2.0f)]
            [Layout(LayoutAttribute.Category.Basic, 1)]
            public float reflectionMultiplier;

            [Tooltip("Maximum reflection distance in world units.")]
            [Range(0.5f, 1000.0f)]
            [Layout(LayoutAttribute.Category.Basic, 2)]
            public float maxDistance;
            
            [Tooltip("How far away from the maxDistance to begin fading SSR.")]
            [Range(0.0f, 1000.0f)]
            [Layout(LayoutAttribute.Category.Basic, 3)]
            public float fadeDistance;
            
            [Tooltip("Higher = fade out SSRR near the edge of the screen so that reflections don't pop under camera motion.")]
            [Range(0.0f, 1.0f)]
            [Layout(LayoutAttribute.Category.Basic, 4)]
            public float screenEdgeFading;
            
            [Tooltip("Enable for better reflections of very bright objects at a performance cost")]
            [Layout(LayoutAttribute.Category.Basic, 5)]
            public bool enableHDR;

            // When enabled, we just add our reflections on top of the existing ones. This is physically incorrect, but several
            // popular demos and games have taken this approach, and it does hide some artifacts.
            [Tooltip("Add reflections on top of existing ones. Not physically correct.")]
            [Layout(LayoutAttribute.Category.Basic, 6)]
            public bool additiveReflection;

            /// REFLECTIONS
            [Tooltip("Max raytracing length.")]
            [Range(16, 2048)]
            [Layout(LayoutAttribute.Category.Reflections, 1)]
            public int maxSteps;
            
            [Tooltip("Log base 2 of ray tracing coarse step size. Higher traces farther, lower gives better quality silhouettes.")]
            [Range(0, 4)]
            [Layout(LayoutAttribute.Category.Reflections, 2)]
            public int rayStepSize;
            
            [Tooltip("Typical thickness of columns, walls, furniture, and other objects that reflection rays might pass behind.")]
            [Range(0.01f, 10.0f)]
            [Layout(LayoutAttribute.Category.Reflections, 3)]
            public float widthModifier;
            
            [Tooltip("Increase if reflections flicker on very rough surfaces.")]
            [Range(0.0f, 1.0f)]
            [Layout(LayoutAttribute.Category.Reflections, 4)]
            public float smoothFallbackThreshold;
            
            [Tooltip("Start falling back to non-SSR value solution at smoothFallbackThreshold - smoothFallbackDistance, with full fallback occuring at smoothFallbackThreshold.")]
            [Range(0.0f, 0.2f)]
            [Layout(LayoutAttribute.Category.Reflections, 5)]
            public float smoothFallbackDistance;
            
            [Tooltip("Amplify Fresnel fade out. Increase if floor reflections look good close to the surface and bad farther 'under' the floor.")]
            [Range(0.0f, 1.0f)]
            [Layout(LayoutAttribute.Category.Reflections, 6)]
            public float fresnelFade;

            [Tooltip("Higher values correspond to a faster Fresnel fade as the reflection changes from the grazing angle.")]
            [Range(0.1f, 10.0f)]
            [Layout(LayoutAttribute.Category.Reflections, 7)]
            public float fresnelFadePower;
            
            [Tooltip("Controls how blurry reflections get as objects are further from the camera. 0 is constant blur no matter trace distance or distance from camera. 1 fully takes into account both factors.")]
            [Range(0.0f, 1.0f)]
            [Layout(LayoutAttribute.Category.Reflections, 8)]
            public float distanceBlur;

            /// ADVANCED
            [Range(0.0f, 0.99f)]
            [Tooltip("Increase to decrease flicker in scenes; decrease to prevent ghosting (especially in dynamic scenes). 0 gives maximum performance.")]
            [Layout(LayoutAttribute.Category.Advanced, 1)]
            public float temporalFilterStrength;

            [Tooltip("Enable to limit ghosting from applying the temporal filter.")]
            [Layout(LayoutAttribute.Category.Advanced, 2)]
            public bool useTemporalConfidence;

            [Tooltip("Improves quality in scenes with varying smoothness, at a potential performance cost.")]
            [Layout(LayoutAttribute.Category.Advanced, 3)]
            public bool traceEverywhere;
            
            [Tooltip("Enable to force more surfaces to use reflection probes if you see streaks on the sides of objects or bad reflections of their backs.")] 
            [Layout(LayoutAttribute.Category.Advanced, 4)]
            public bool treatBackfaceHitAsMiss;

            [Tooltip("Enable for a performance gain in scenes where most glossy objects are horizontal, like floors, water, and tables. Leave off for scenes with glossy vertical objects.")]
            [Layout(LayoutAttribute.Category.Advanced, 5)]
            public bool suppressBackwardsRays;

            [Tooltip("Improve visual fidelity of reflections on rough surfaces near corners in the scene, at the cost of a small amount of performance.")]
            [Layout(LayoutAttribute.Category.Advanced, 6)]
            public bool improveCorners;

            [Tooltip("Half resolution SSRR is much faster, but less accurate. Quality can be reclaimed for some performance by doing the resolve at full resolution.")]
            [Layout(LayoutAttribute.Category.Advanced, 7)]
            public SSRResolution resolution;

            [Tooltip("Drastically improves reflection reconstruction quality at the expense of some performance.")]
            [Layout(LayoutAttribute.Category.Advanced, 8)]
            public bool bilateralUpsample;
            
            [Tooltip("Improve visual fidelity of mirror reflections at the cost of a small amount of performance.")]
            [Layout(LayoutAttribute.Category.Advanced, 9)]
            public bool reduceBanding;
            
            [Tooltip("Enable to limit the effect a few bright pixels can have on rougher surfaces")]
            [Layout(LayoutAttribute.Category.Advanced, 10)]
            public bool highlightSuppression;

            /// DEBUG
            [Tooltip("Various Debug Visualizations")]
            [Layout(LayoutAttribute.Category.Debug, 1)]
            public SSRDebugMode debugMode;

            // If false, just uses the glossy GI buffer results
            [Tooltip("Uncheck to disable SSR without disabling the entire component")]
            [Layout(LayoutAttribute.Category.Debug, 2)]
            public bool enable;

            private static readonly SSRSettings s_Performance = new SSRSettings
            {
                maxSteps = 64,
                rayStepSize = 4,
                widthModifier = 0.5f,
                screenEdgeFading = 0,
                maxDistance = 10.0f,
                fadeDistance = 10.0f,
                reflectionMultiplier = 1.0f,
                treatBackfaceHitAsMiss = false,
                suppressBackwardsRays = true,
                enableHDR = false,
                smoothFallbackThreshold = 0.4f,
                traceEverywhere = false,
                distanceBlur = 1.0f,
                fresnelFade = 0.2f,
                resolution = SSRResolution.HalfResolution,
                bilateralUpsample = false,
                fresnelFadePower = 2.0f,
                smoothFallbackDistance = 0.05f,
                improveCorners = false,
                reduceBanding = false,
                additiveReflection = false,
                debugMode = SSRDebugMode.None,
                enable = true
            };

            private static readonly SSRSettings s_Default = new SSRSettings
            {
                maxSteps = 128,
                rayStepSize = 3,
                widthModifier = 0.5f,
                screenEdgeFading = 0.03f,
                maxDistance = 100.0f,
                fadeDistance = 100.0f,
                reflectionMultiplier = 1.0f,
                treatBackfaceHitAsMiss = false,
                suppressBackwardsRays = false,
                enableHDR = true,
                smoothFallbackThreshold = 0.2f,
                traceEverywhere = true,
                distanceBlur = 1.0f,
                fresnelFade = 0.2f,
                resolution = SSRResolution.HalfTraceFullResolve,
                bilateralUpsample = true,
                fresnelFadePower = 2.0f,
                smoothFallbackDistance = 0.05f,
                improveCorners = true,
                reduceBanding = true,
                additiveReflection = false,
                debugMode = SSRDebugMode.None,
                enable = true
            };

            private static readonly SSRSettings s_HighQuality = new SSRSettings
            {
                maxSteps = 512,
                rayStepSize = 1,
                widthModifier = 0.5f,
                screenEdgeFading = 0.03f,
                maxDistance = 100.0f,
                fadeDistance = 100.0f,
                reflectionMultiplier = 1.0f,
                treatBackfaceHitAsMiss = false,
                suppressBackwardsRays = false,
                enableHDR = true,
                smoothFallbackThreshold = 0.2f,
                traceEverywhere = true,
                distanceBlur = 1.0f,
                fresnelFade = 0.2f,
                resolution = SSRResolution.FullResolution,
                bilateralUpsample = true,
                fresnelFadePower = 2.0f,
                smoothFallbackDistance = 0.05f,
                improveCorners = true,
                reduceBanding = true,
                additiveReflection = false,
                debugMode = SSRDebugMode.None,
                enable = true
            };

            public static SSRSettings performanceSettings
            {
                get { return s_Performance; }
            }

            public static SSRSettings defaultSettings
            {
                get { return s_Default; }
            }

            public static SSRSettings highQualitySettings
            {
                get { return s_HighQuality; }
            }
        }

        [SerializeField]
        public SSRSettings settings = SSRSettings.defaultSettings;

        ///////////// Unexposed Variables //////////////////

        // Perf optimization we still need to test across platforms
        [Tooltip("Enable to try and bypass expensive bilateral upsampling away from edges. There is a slight performance hit for generating the edge buffers, but a potentially high performance savings from bypassing bilateral upsampling where it is unneeded. Test on your target platforms to see if performance improves.")]
        private bool useEdgeDetector = false;

        // Debug variable, useful for forcing all surfaces in a scene to reflection with arbitrary sharpness/roughness
        [Range(-4.0f, 4.0f)]
        private float mipBias = 0.0f;

        // Flag for whether to knock down the reflection term by occlusion stored in the gbuffer. Currently consistently gives
        // better results when true, so this flag is private for now.
        private bool useOcclusion = true;

        // When enabled, all filtering is performed at the highest resolution. This is extraordinarily slow, and should only be used during development.
        private bool fullResolutionFiltering = false;

        // Crude sky fallback, feature-gated until next revision
        private bool fallbackToSky = false;

        // For next release; will improve quality at the expense of performance
        private bool computeAverageRayDistance = false;

        // Internal values for temporal filtering
        private bool m_HasInformationFromPreviousFrame;
        private Matrix4x4 m_PreviousWorldToCameraMatrix;
        private RenderTexture m_PreviousDepthBuffer;
        private RenderTexture m_PreviousHitBuffer;
        private RenderTexture m_PreviousReflectionBuffer;

        public Shader ssrShader;
        private Material ssrMaterial;

        // Shader pass indices used by the effect
        private enum PassIndex
        {
            RayTraceStep1 = 0,
            RayTraceStep2 = 1,
            RayTraceStep4 = 2,
            RayTraceStep8 = 3,
            RayTraceStep16 = 4,
            CompositeFinal = 5,
            Blur = 6,
            CompositeSSR = 7,
            Blit = 8,
            EdgeGeneration = 9,
            MinMipGeneration = 10,
            HitPointToReflections = 11,
            BilateralKeyPack = 12,
            BlitDepthAsCSZ = 13,
            TemporalFilter = 14,
            AverageRayDistanceGeneration = 15,
        }

        public override bool CheckResources()
        {
            CheckSupport(true);
            ssrMaterial = CheckShaderAndCreateMaterial(ssrShader, ssrMaterial);

            if (!isSupported)
                ReportAutoDisable();
            return isSupported;
        }

        void OnDisable()
        {
            if (ssrMaterial)
                DestroyImmediate(ssrMaterial);
            if (m_PreviousDepthBuffer)
                DestroyImmediate(m_PreviousDepthBuffer);
            if (m_PreviousHitBuffer)
                DestroyImmediate(m_PreviousHitBuffer);
            if (m_PreviousReflectionBuffer)
                DestroyImmediate(m_PreviousReflectionBuffer);

            ssrMaterial             = null;
            m_PreviousDepthBuffer     = null;
            m_PreviousHitBuffer       = null;
            m_PreviousReflectionBuffer = null;
        }

        private void PreparePreviousBuffers(int w, int h)
        {
            if (m_PreviousDepthBuffer != null) {
                if ((m_PreviousDepthBuffer.width != w) || (m_PreviousDepthBuffer.height != h))
                {
                    DestroyImmediate(m_PreviousDepthBuffer);
                    DestroyImmediate(m_PreviousHitBuffer);
                    DestroyImmediate(m_PreviousReflectionBuffer);
                    m_PreviousDepthBuffer         = null;
                    m_PreviousHitBuffer           = null;
                    m_PreviousReflectionBuffer    = null;
                }
            }
            if (m_PreviousDepthBuffer == null)
            {
                m_PreviousDepthBuffer         = new RenderTexture(w, h, 0, RenderTextureFormat.RFloat);
                m_PreviousHitBuffer           = new RenderTexture(w, h, 0, RenderTextureFormat.ARGBHalf);
                m_PreviousReflectionBuffer    = new RenderTexture(w, h, 0, RenderTextureFormat.ARGBHalf);
            }
        }

        [ImageEffectOpaque]
        public void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            
            bool doTemporalFilterThisFrame = m_HasInformationFromPreviousFrame && settings.temporalFilterStrength > 0.0;
            m_HasInformationFromPreviousFrame = false;
            // No shaders set up, or not supported? Just blit source to destination.
            if (CheckResources() == false)
            {
                Graphics.Blit(source, destination);
                return;
            }
            // Not using deferred shading? Just blit source to destination.
            if (Camera.current.actualRenderingPath != RenderingPath.DeferredShading)
            {
                Graphics.Blit(source, destination);
                return;                
            }

            var rtW = source.width;
            var rtH = source.height;
            
            // RGB: Normals, A: Roughness.
            // Has the nice benefit of allowing us to control the filtering mode as well.
            RenderTexture bilateralKeyTexture = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGB32);
            bilateralKeyTexture.filterMode = FilterMode.Point;
            Graphics.Blit(source, bilateralKeyTexture, ssrMaterial, (int)PassIndex.BilateralKeyPack);
            ssrMaterial.SetTexture("_NormalAndRoughnessTexture", bilateralKeyTexture);

            float sWidth = source.width;
            float sHeight = source.height;

            Vector2 sourceToTempUV = new Vector2(sWidth / rtW, sHeight / rtH);

            int downsampleAmount = (settings.resolution == SSRResolution.FullResolution) ? 1 : 2;

            rtW = rtW / downsampleAmount;
            rtH = rtH / downsampleAmount;

            ssrMaterial.SetVector("_SourceToTempUV", new Vector4(sourceToTempUV.x, sourceToTempUV.y, 1.0f / sourceToTempUV.x, 1.0f / sourceToTempUV.y));


            Matrix4x4 P = GetComponent<Camera>().projectionMatrix;
            Vector4 projInfo = new Vector4
                ((-2.0f / (Screen.width * P[0])),
                 (-2.0f / (Screen.height * P[5])),
                 ((1.0f - P[2]) / P[0]),
                 ((1.0f + P[6]) / P[5]));

            /** The height in pixels of a 1m object if viewed from 1m away. */
            float pixelsPerMeterAtOneMeter = sWidth / (-2.0f * (float)(Math.Tan(GetComponent<Camera>().fieldOfView/180.0 * Math.PI * 0.5)));
            ssrMaterial.SetFloat("_PixelsPerMeterAtOneMeter", pixelsPerMeterAtOneMeter);


            float sx = Screen.width / 2.0f;
            float sy = Screen.height / 2.0f;

            Matrix4x4 warpToScreenSpaceMatrix = new Matrix4x4();
            warpToScreenSpaceMatrix.SetRow(0, new Vector4(sx, 0.0f, 0.0f, sx));
            warpToScreenSpaceMatrix.SetRow(1, new Vector4(0.0f, sy, 0.0f, sy));
            warpToScreenSpaceMatrix.SetRow(2, new Vector4(0.0f, 0.0f, 1.0f, 0.0f));
            warpToScreenSpaceMatrix.SetRow(3, new Vector4(0.0f, 0.0f, 0.0f, 1.0f));

            Matrix4x4 projectToPixelMatrix = warpToScreenSpaceMatrix * P;

            ssrMaterial.SetVector("_ScreenSize", new Vector2(Screen.width, Screen.height));
            ssrMaterial.SetVector("_ReflectionBufferSize", new Vector2(rtW, rtH));
            Vector2 invScreenSize = new Vector2((float)(1.0 / (double)Screen.width), (float)(1.0 / (double)Screen.height));

            Matrix4x4 worldToCameraMatrix = GetComponent<Camera>().worldToCameraMatrix;
            Matrix4x4 cameraToWorldMatrix = GetComponent< Camera > ().worldToCameraMatrix.inverse;
            ssrMaterial.SetVector("_InvScreenSize", invScreenSize);
            ssrMaterial.SetVector("_ProjInfo", projInfo); // used for unprojection
            ssrMaterial.SetMatrix("_ProjectToPixelMatrix", projectToPixelMatrix);
            ssrMaterial.SetMatrix("_WorldToCameraMatrix", worldToCameraMatrix);
            ssrMaterial.SetMatrix("_CameraToWorldMatrix", cameraToWorldMatrix);
            ssrMaterial.SetInt("_EnableRefine", settings.reduceBanding ? 1 : 0);
            ssrMaterial.SetInt("_AdditiveReflection", settings.additiveReflection ? 1 : 0);
            ssrMaterial.SetInt("_ImproveCorners", settings.improveCorners ? 1 : 0);
            ssrMaterial.SetFloat("_ScreenEdgeFading", settings.screenEdgeFading);
            ssrMaterial.SetFloat("_MipBias", mipBias);
            ssrMaterial.SetInt("_UseOcclusion", useOcclusion ? 1 : 0);
            ssrMaterial.SetInt("_BilateralUpsampling", settings.bilateralUpsample ? 1 : 0);
            ssrMaterial.SetInt("_FallbackToSky", fallbackToSky ? 1 : 0);
            ssrMaterial.SetInt("_TreatBackfaceHitAsMiss", settings.treatBackfaceHitAsMiss ? 1 : 0);
            ssrMaterial.SetInt("_SuppressBackwardsRays", settings.suppressBackwardsRays ? 1 : 0);
            ssrMaterial.SetInt("_TraceEverywhere", settings.traceEverywhere ? 1 : 0);

            float z_f = GetComponent<Camera>().farClipPlane;
            float z_n = GetComponent<Camera>().nearClipPlane;

            Vector3 cameraClipInfo = (float.IsPositiveInfinity(z_f)) ?
                new Vector3(z_n, -1.0f, 1.0f) :
                    new Vector3(z_n * z_f, z_n - z_f, z_f);

            ssrMaterial.SetVector("_CameraClipInfo", cameraClipInfo);
            ssrMaterial.SetFloat("_MaxRayTraceDistance", settings.maxDistance);
            ssrMaterial.SetFloat("_FadeDistance", settings.fadeDistance);
            ssrMaterial.SetFloat("_LayerThickness", settings.widthModifier);

            const int maxMip = 5;
            RenderTexture[] reflectionBuffers;
            RenderTextureFormat intermediateFormat = settings.enableHDR ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
            
            reflectionBuffers = new RenderTexture[maxMip];
            for (int i = 0; i < maxMip; ++i)
            {
                if (fullResolutionFiltering)
                    reflectionBuffers[i] = RenderTexture.GetTemporary(rtW, rtH, 0, intermediateFormat);
                else
                    reflectionBuffers[i] = RenderTexture.GetTemporary(rtW >> i, rtH >> i, 0, intermediateFormat);
                // We explicitly interpolate during bilateral upsampling.
                reflectionBuffers[i].filterMode = settings.bilateralUpsample ? FilterMode.Point : FilterMode.Bilinear;
            }

            ssrMaterial.SetInt("_EnableSSR", settings.enable ? 1 : 0);
            ssrMaterial.SetInt("_DebugMode", (int)settings.debugMode);

            ssrMaterial.SetInt("_MaxSteps", settings.maxSteps);

            RenderTexture rayHitTexture = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBHalf);

            // We have 5 passes for different step sizes
            int tracePass = Mathf.Clamp(settings.rayStepSize, 0, 4);
            Graphics.Blit(source, rayHitTexture, ssrMaterial, tracePass);

            ssrMaterial.SetTexture("_HitPointTexture", rayHitTexture);
            // Resolve the hitpoints into the mirror reflection buffer
            Graphics.Blit(source, reflectionBuffers[0], ssrMaterial, (int)PassIndex.HitPointToReflections);


            ssrMaterial.SetTexture("_ReflectionTexture0", reflectionBuffers[0]);
            ssrMaterial.SetInt("_FullResolutionFiltering", fullResolutionFiltering ? 1 : 0);

            ssrMaterial.SetFloat("_MaxRoughness", 1.0f - settings.smoothFallbackThreshold);
            ssrMaterial.SetFloat("_RoughnessFalloffRange", settings.smoothFallbackDistance);

            ssrMaterial.SetFloat("_SSRMultiplier", settings.reflectionMultiplier);

            RenderTexture[] edgeTextures = new RenderTexture[maxMip];
            if (settings.bilateralUpsample && useEdgeDetector)
            {
                edgeTextures[0] = RenderTexture.GetTemporary(rtW, rtH);
                Graphics.Blit(source, edgeTextures[0], ssrMaterial, (int)PassIndex.EdgeGeneration);
                for (int i = 1; i < maxMip; ++i)
                {
                    edgeTextures[i] = RenderTexture.GetTemporary(rtW >> i, rtH >> i);
                    ssrMaterial.SetInt("_LastMip", i - 1);
                    Graphics.Blit(edgeTextures[i - 1], edgeTextures[i], ssrMaterial, (int)PassIndex.MinMipGeneration);
                }
            }

            // Generate the blurred low-resolution buffers
            for (int i = 1; i < maxMip; ++i)
            {
                RenderTexture inputTex = reflectionBuffers[i - 1];

                RenderTexture hBlur;
                if (fullResolutionFiltering)
                    hBlur = RenderTexture.GetTemporary(rtW, rtH, 0, intermediateFormat);
                else
                {
                    int lowMip = i;
                    hBlur = RenderTexture.GetTemporary(rtW >> lowMip, rtH >> (i - 1), 0, intermediateFormat);
                }
                for (int j = 0; j < (fullResolutionFiltering ? (i * i) : 1); ++j)
                {
                    // Currently we blur at the resolution of the previous mip level, we could save bandwidth by blurring directly to the lower resolution.
                    ssrMaterial.SetVector("_Axis", new Vector4(1.0f, 0.0f, 0.0f, 0.0f));
                    ssrMaterial.SetFloat("_CurrentMipLevel", i - 1.0f);

                    Graphics.Blit(inputTex, hBlur, ssrMaterial, (int)PassIndex.Blur);

                    ssrMaterial.SetVector("_Axis", new Vector4(0.0f, 1.0f, 0.0f, 0.0f));

                    inputTex = reflectionBuffers[i];
                    Graphics.Blit(hBlur, inputTex, ssrMaterial, (int)PassIndex.Blur);
                    
                }

                ssrMaterial.SetTexture("_ReflectionTexture" + i, reflectionBuffers[i]);
                
                RenderTexture.ReleaseTemporary(hBlur);
            }

            if (settings.bilateralUpsample && useEdgeDetector)
            {
                for (int i = 0; i < maxMip; ++i)
                    ssrMaterial.SetTexture("_EdgeTexture" + i, edgeTextures[i]);
            }
            ssrMaterial.SetInt("_UseEdgeDetector", useEdgeDetector ? 1 : 0);

            RenderTexture averageRayDistanceBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.RHalf);
            if (computeAverageRayDistance)
            {
                Graphics.Blit(source, averageRayDistanceBuffer, ssrMaterial, (int)PassIndex.AverageRayDistanceGeneration);
            }
            ssrMaterial.SetInt("_UseAverageRayDistance", computeAverageRayDistance ? 1 : 0);
            ssrMaterial.SetTexture("_AverageRayDistanceBuffer", averageRayDistanceBuffer);
            bool resolveDiffersFromTraceRes = (settings.resolution == SSRResolution.HalfTraceFullResolve);
            RenderTexture finalReflectionBuffer = RenderTexture.GetTemporary(resolveDiffersFromTraceRes ? source.width : rtW, resolveDiffersFromTraceRes ? source.height : rtH, 0, intermediateFormat);

            ssrMaterial.SetFloat("_FresnelFade", settings.fresnelFade);
            ssrMaterial.SetFloat("_FresnelFadePower", settings.fresnelFadePower);
            ssrMaterial.SetFloat("_DistanceBlur", settings.distanceBlur);
            ssrMaterial.SetInt("_HalfResolution", (settings.resolution != SSRResolution.FullResolution) ? 1 : 0);
            ssrMaterial.SetInt("_HighlightSuppression", settings.highlightSuppression ? 1 : 0);
            Graphics.Blit(reflectionBuffers[0], finalReflectionBuffer, ssrMaterial, (int)PassIndex.CompositeSSR);
            ssrMaterial.SetTexture("_FinalReflectionTexture", finalReflectionBuffer);


            RenderTexture temporallyFilteredBuffer = RenderTexture.GetTemporary(resolveDiffersFromTraceRes ? source.width : rtW, resolveDiffersFromTraceRes ? source.height : rtH, 0, intermediateFormat);
            if (doTemporalFilterThisFrame)
            {
                ssrMaterial.SetInt("_UseTemporalConfidence", settings.useTemporalConfidence ? 1 : 0);
                ssrMaterial.SetFloat("_TemporalAlpha", settings.temporalFilterStrength);
                ssrMaterial.SetMatrix("_CurrentCameraToPreviousCamera", m_PreviousWorldToCameraMatrix * cameraToWorldMatrix);
                ssrMaterial.SetTexture("_PreviousReflectionTexture", m_PreviousReflectionBuffer);
                ssrMaterial.SetTexture("_PreviousCSZBuffer", m_PreviousDepthBuffer);
                Graphics.Blit(source, temporallyFilteredBuffer, ssrMaterial, (int) PassIndex.TemporalFilter);

                ssrMaterial.SetTexture("_FinalReflectionTexture", temporallyFilteredBuffer);
                Graphics.Blit(source, destination, ssrMaterial, (int) PassIndex.CompositeFinal);
            }
            else
                Graphics.Blit(source, destination, ssrMaterial, (int) PassIndex.CompositeFinal);


            if (settings.temporalFilterStrength > 0.0)
            {
                m_PreviousWorldToCameraMatrix = worldToCameraMatrix;
                PreparePreviousBuffers(source.width, source.height);
                Graphics.Blit(source, m_PreviousDepthBuffer, ssrMaterial, (int)PassIndex.BlitDepthAsCSZ);
                Graphics.Blit(rayHitTexture, m_PreviousHitBuffer);
                Graphics.Blit(doTemporalFilterThisFrame ? temporallyFilteredBuffer : finalReflectionBuffer, m_PreviousReflectionBuffer);

                m_HasInformationFromPreviousFrame = true;
            }
            RenderTexture.ReleaseTemporary(temporallyFilteredBuffer);
            RenderTexture.ReleaseTemporary(averageRayDistanceBuffer);
            RenderTexture.ReleaseTemporary(bilateralKeyTexture);
            RenderTexture.ReleaseTemporary(rayHitTexture);

            if (settings.bilateralUpsample && useEdgeDetector)
            {
                for (int i = 0; i < maxMip; ++i)
                {
                    RenderTexture.ReleaseTemporary(edgeTextures[i]);
                }
            }
            RenderTexture.ReleaseTemporary(finalReflectionBuffer);
            for (int i = 0; i < maxMip; ++i)
            {
                RenderTexture.ReleaseTemporary(reflectionBuffers[i]);
            }
        }
    }
}

