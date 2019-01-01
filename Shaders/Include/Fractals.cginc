#ifndef FRACTALS_CGINC
#define FRACTALS_CGINC

#include "./Utils.cginc"

inline float RecursiveTetrahedron(float3 p, int loop)
{
    p = repeat(p / 2, 3.0);

    const float3 a1 = float3( 1.0,  1.0,  1.0);
    const float3 a2 = float3(-1.0, -1.0,  1.0);
    const float3 a3 = float3( 1.0, -1.0, -1.0);
    const float3 a4 = float3(-1.0,  1.0, -1.0);

    const float scale = 2.0;
    float d;
    for (int n = 0; n < loop; ++n) {
        float3 c = a1; 
        float minDist = length(p - a1);
        d = length(p - a2); if (d < minDist) { c = a2; minDist = d; }
        d = length(p - a3); if (d < minDist) { c = a3; minDist = d; }
        d = length(p - a4); if (d < minDist) { c = a4; minDist = d; }
        p = scale * p - c * (scale - 1.0);
    }
 
    return length(p) * pow(scale, float(-n));
}

#endif
