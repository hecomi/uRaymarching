#ifndef VERTS_H
#define VERTS_H

#include "UnityCG.cginc"
#include "./Structs.cginc"

float _MinDistance;
int _Loop;
float4 _Diffuse;
float4 _Specular;
float4 _Emission;

VertScreenOutput Vert(VertScreenInput i)
{
    VertScreenOutput o;
    o.vertex = i.vertex;
    o.screenPos = i.vertex;
    return o;
}

GBufferOut Frag(VertScreenOutput i)
{
    RaymarchInfo ray;
    UNITY_INITIALIZE_OUTPUT(RaymarchInfo, ray);
    ray.rayDir = GetCameraDirection(i.screenPos);
    ray.startPos = GetCameraPosition() + _ProjectionParams.y * ray.rayDir;
    ray.minDistance = _MinDistance;
    ray.maxDistance = GetCameraMaxDistance();
    ray.loop = _Loop;

    Raymarch(ray);

    GBufferOut o;
    o.diffuse  = _Diffuse;
    o.specular = _Specular;
    o.emission = _Emission;
    o.normal   = float4(ray.normal, 1.0);
#ifndef DO_NOT_OUTPUT_DEPTH
    o.depth    = ray.depth;
#endif

#ifdef POST_EFFECT
    POST_EFFECT(ray, o);
#endif

#ifndef UNITY_HDR_ON
    o.emission = exp2(-o.emission);
#endif

    return o;
}

#endif