uRaymarching - Legacy Pipelines
===============================

Conditions
----------
- `Blend`
  - Create a `Blend X X` line.
  - Please check if you want to create a transparent shader.
- `Shadow Caster`
  - Create `ShadowCaster` pass.
  - Please check if you want a shadow of a raymarching object.
- `Full Screen`
  - Please check if you use `RamyarchingRenderer` to do fullscreen raymarching.
  - If checked, emit rays from a camera, if not, from a cube polygon surface.
- `World Space`
  - The given `pos` in a distance function becomes world-space one.
- `Follow Object Scale`
  - If checked, `pos` in a distance function is scaled by the object scale.
- `Camera Inside Object`
  - Check if the camera position is inside the object, and then if so, emit ray from camera (not from a polygon surface).
  - Please set the culling as `Cull Off`.
- `Use Raymarching Depth`
  - If checked, output a raymarching depth, and if not, output a polygon depth.
- `Use Camera Depth Texture`
  - The occlusion with the other objects is calculated using the `CameraDepthTexture`.
  - Please check in the case that you create a transparent shader and set `ZWrite Off` to a material.
- `Disable View Culling`
  - Please use this only for the fullscreen raymarching with *Camera Inside Object* option.
- `Spherical Harmonics Per Pixel`
  - By default the SH calculation is done in a vertex shader (i.e. only 8 vertices of a cube) but if you create a complex shape and the calculation of the SH is bad, please check this flag to calculate it in a fragment shader (needs more cost than the unchecked case).
- `Use Grab Pass`
  - If checked, insert `GrabPass {}` line before `ForwardBase` pass (see an example at [uRaymarchingExample](https://github.com/hecomi/uRaymarchingExamples) repository).
- `Forward Add`
  - Create a `ForwardAdd` pass to calculate the effect from additional lights.
- `Fallback To Standard Shader`
  - Create a `Fallback` line.
  - If you want a shadow of the polygon object for the better performance, please uncheck *Shadow Caster* and check this.


Variables
---------
- Render Type
  - `RenderType` tag value like `Opaque`, `Transparent`, and `TransparentCutout`.
- Render Queue
  - `Queue` tag value like `Geometry`, `AlphaTest`, and `Transparent`.
- Object Shape
  - Clip the raymarching area inside cube or not (see below).
  - CUBE
    - <img src="https://raw.githubusercontent.com/wiki/hecomi/uRaymarching/clip_cube.gif" width="480" />
  - NONE
    - <img src="https://raw.githubusercontent.com/wiki/hecomi/uRaymarching/clip_none.gif" width="480" />


Post Effect
-----------

`PostEffectOutput` is the following type in each template.

- Forward > Standard
  - `SurfaceOutputStandard`
- Forward > Unlit
  - `float4`
- Deferred > Standard
  - `SurfaceOutputStandard`
- Deferred > Direct GBuffer
  - `GBufferOut`


```c
struct GBufferOut
{
    half4 diffuse  : SV_Target0; // rgb: diffuse,  a: occlusion
    half4 specular : SV_Target1; // rgb: specular, a: smoothness
    half4 normal   : SV_Target2; // rgb: normal,   a: unused
    half4 emission : SV_Target3; // rgb: emission, a: unused
#ifdef USE_RAYMARCHING_DEPTH
    float depth    : SV_Depth;
#endif
};
```


Fullscreen
----------
<img src="https://raw.githubusercontent.com/wiki/hecomi/uRaymarching/world.gif" width="720" />

The `RaymarchingRenderer` component creates a quad plane and renders raymarching objects on it using `CommandBuffer`.

<img src="https://raw.githubusercontent.com/wiki/hecomi/uRaymarching/raymarching-renderer-component.png" width="720" />

Attach a `RayamarchingRenderer` component to an arbitrary object, and create a material which selects a shader created by uRaymarching with the flag of *Full Screen* (please see the *Conditions* section in this document). Then, set it to the *Material* field, and select the rendering timing from the *Pass* drop-down list. You can see the raymarching world with the distance function you write, and it intersects polygon objects.

However, now this has some problems regarding lightings and VR. Please see the following *Known Issues* section regarding those limitations.


Known Issues
------------
### DepthNormalTexture in forward pass

In forward pass, `DepthTexture` is rendererd using the `ShadowCaster` pass but `DepthNormalsTexture` uses the built-in replacement shader.

- [Unity - Manual: Camera's Depth Texture](https://docs.unity3d.com/Manual/SL-CameraDepthTexture.html)
- [Unity - Manual: Rendering with Replaced Shaders](https://docs.unity3d.com/Manual/SL-ShaderReplacement.html)

This built-in shader outputs the depth of a polygon surface, so post effects which use `DepthNormalsTexture` like the ambient occlusion in PostProcessing generate wrong results. For now, I don't have any good idea to overwrite it with raymarching results.

### No lighting with `RaymarchingRenderer` in forward path

In forward path, when rendering raymarching objects with `RaymarchingRenderer`, some shader keywords related to the lighting are not defined because it uses `CommandBuffer`. This causes wrong lighting result. So if you want to do fullscreen raymarching in forward path with lighting, please create a large box following the camera (as a child of camera), and set `Cull Off` or `Cull Front` flag, then activate `Camera Inside Object`.

### In VR, both eyes output same image with `RarymarchingRenderer`

In VR, the cameras for two eyes seem to tell the same position in a shader when using `RaymarchingRenderer`. I'm not sure how to fix it now, so please do not use it for VR. Instead of using it, please create a shader which enables `Camera Inside Object` and `Disable View Culling` and set `Cull` flag as `Off` in the material inspector. Using `Camera Inside Object` with `Cull Off` allows you to enter raymarching objects. And `Disable View Culling` outputs faked z value in clip space and keeps the raymarching object always visible even if the outside cube polygon is very large. Please see the `Mod World for VR` scene as an example.
