uRaymarching - UniversalRP
==========================

Requirements
------------
- Unity 2019.3.0f3 or later


Conditions
----------
- `Shadow Caster`
  - Create `ShadowCaster` pass.
  - Please check if you want a shadow of a raymarching object.
- `World Space`
  - The given `pos` in a distance function becomes world-space one.
  - If not, `pos` becomes an object-space one.
- `Object Scale`
  - If checked, `pos` in a distance function is scaled by the object scale.
- `Check If Inside Object`
  - Check if the camera position is inside the object, and then if so, emit ray from the near clip plane.
  - Please set the `Culling` in *Material Properties* as `Cull Off`.
- `Ray Stops At Depth Texture`
  - The occlusion with the other objects is calculated using the `CameraDepthTexture`.
  - Please check this with the setting of a transparent object.
    - Set `Render Type` as `Transparent`.
    - Set `Render Queue` as `Transparent` or greater.
    - Uncheck `ZWrite` in *Material Properties*.
  - And please check URP is generating `CameraDepthTexture` or not in `Depth Prepass` stage from *Frame Debug* window.
    - If you don't use *Cascaded Shadow*, the texture may not be created.
- `Ray Starts From Depth Texture`
  - The ray starts from depth texture to avoid the same calculation done in both `DepthOnly` and `ForwardLit` passes.
  - Please check URP is generating `CameraDepthTexture` or not.

Variables
---------
- Render Type
  - `RenderType` tag value like `Opaque`, `Transparent`, and `TransparentCutout`.
- Render Queue
  - `Queue` tag value like `Geometry`, `AlphaTest`, and `Transparent`.
- LOD
  - `LOD` setting in a shader.
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

