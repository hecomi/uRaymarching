#ifndef VERT_FRAG_SHADOW_OBJECT_CGINC
#define VERT_FRAG_SHADOW_OBJECT_CGINC

#include "AutoLight.cginc"
#include "UnityCG.cginc"
#include "./Structs.cginc"
#include "./Raymarching.cginc"
#include "./Utils.cginc"

float _ShadowExtraBias;
float _ShadowMinDistance;
int _ShadowLoop;

struct appdata 
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv     : TEXCOORD0;
};

struct v2f
{
    V2F_SHADOW_CASTER;
    float4 worldPos  : TEXCOORD1;
    float3 normal    : TEXCOORD2;
    float4 projPos   : TEXCOORD3;
};

inline float4 ApplyLinearShadowBias(float4 clipPos)
{
#if !(defined(SHADOWS_CUBE) && defined(SHADOWS_CUBE_IN_DEPTH_TEX))
    #if defined(UNITY_REVERSED_Z)
    clipPos.z += max(-1.0, min((unity_LightShadowBias.x - _ShadowExtraBias) / clipPos.w, 0.0));
    #else
    clipPos.z += saturate((unity_LightShadowBias.x + _ShadowExtraBias) / clipPos.w);
    #endif
#endif

#if defined(UNITY_REVERSED_Z)
    float clamped = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#else
    float clamped = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#endif
    clipPos.z = lerp(clipPos.z, clamped, unity_LightShadowBias.y);
    return clipPos;
}

v2f Vert(appdata v)
{
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    o.pos = UnityObjectToClipPos(v.vertex);
    #ifdef DISABLE_VIEW_CULLING
    o.pos.z = 1;
    #endif
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = mul(unity_ObjectToWorld, v.normal);
    o.projPos = ComputeNonStereoScreenPos(o.pos);
    COMPUTE_EYEDEPTH(o.projPos.z);
    return o;
}

#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)

float4 Frag(v2f i) : SV_Target
{
    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = GetCameraDirection(i.projPos);
    ray.startPos = i.worldPos;
    ray.minDistance = _ShadowMinDistance;
    ray.maxDistance = GetCameraFarClip();
    ray.maxLoop = _ShadowLoop;

    if (!_Raymarch(ray)) discard;

    i.vec = ray.endPos - _LightPositionRange.xyz;
    SHADOW_CASTER_FRAGMENT(i);
}

#else

void Frag(
    v2f i, 
    out float4 outColor : SV_Target, 
    out float  outDepth : SV_Depth)
{
    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.startPos = i.worldPos;
    ray.minDistance = _ShadowMinDistance;
    ray.maxDistance = GetCameraFarClip();
    ray.maxLoop = _ShadowLoop;

    if (IsCameraPerspective()) {
        // Hack: This pass run in the UpdateDepthTexture stage.
        if (abs(unity_LightShadowBias.x) < 1e-5) {
            ray.rayDir = normalize(i.worldPos - GetCameraPosition());
#ifdef CAMERA_INSIDE_OBJECT
            float3 startPos = GetCameraPosition() + GetDistanceFromCameraToNearClipPlane(i.projPos) * ray.rayDir;
            if (IsInnerObject(startPos)) {
                ray.startPos = startPos;
                ray.polyNormal = -ray.rayDir;
            }
#endif
        // Run in the SpotLight shadow stage.
        } else {
            ray.rayDir = GetCameraDirection(i.projPos);
        }
    } else {
        ray.rayDir = GetCameraForward();
    }

    if (!_Raymarch(ray)) discard;

    float4 opos = mul(unity_WorldToObject, float4(ray.endPos, 1.0));
    float3 worldNormal = DecodeNormal(ray.normal);
    opos = UnityClipSpaceShadowCasterPos(opos, worldNormal);
    opos = ApplyLinearShadowBias(opos);
    outColor = outDepth = EncodeDepth(opos);
}

#endif

#endif