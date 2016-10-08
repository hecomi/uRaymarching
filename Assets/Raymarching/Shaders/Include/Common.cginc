#ifndef COMMON_H
#define COMMON_H

#ifndef WORLD_SPACE
float4 _Scale;
#endif

#define UNITY_PASS_DEFERRED
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "./Structs.cginc"
#include "./Utils.cginc"
#include "./Camera.cginc"
#include "./Math.cginc"
#include "./Primitives.cginc"

#endif