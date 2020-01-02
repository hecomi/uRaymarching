uRaymarching - UniversalRP
==========================

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

- UniversalRP > Lit
  - Same lighting as the built-in `Universal Render Pipelin/Lit` shader.
- UniversalRP > Unlit
  - No lighting, and same as the built-in `Universal Render Pipelin/Unlit` shader.

