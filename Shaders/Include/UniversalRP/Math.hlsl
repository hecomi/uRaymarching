#ifndef URAYMARCHING_MATH_HLSL
#define URAYMARCHING_MATH_HLSL

float Rand(float2 seed)
{
    return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
}

inline float Mod(float a, float b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float2 Mod(float2 a, float2 b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float3 Mod(float3 a, float3 b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float SmoothMin(float d1, float d2, float k)
{
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

inline float Repeat(float pos, float span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float2 Repeat(float2 pos, float2 span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float3 Repeat(float3 pos, float3 span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float3 Rotate(float3 p, float angle, float3 axis)
{
    float3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    float3x3 m = float3x3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return mul(m, p);
}

inline float3 TwistY(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return mul(m, p);
}

inline float3 TwistX(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
        1.0, 0.0, 0.0,
        0.0,   c,   s,
        0.0,  -s,   c
    );
    return mul(m, p);
}

inline float3 TwistZ(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c,   s, 0.0,
         -s,   c, 0.0,
        0.0, 0.0, 1.0
    );
    return mul(m, p);
}

#endif
