#ifndef COMMON_H
#define COMMON_H

float3 _Scale = float3(1, 1, 1);

#define UNITY_PASS_DEFERRED
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "./Structs.cginc"
#include "./Utils.cginc"
#include "./Camera.cginc"
#include "./Math.cginc"
#include "./Primitives.cginc"

#endif
