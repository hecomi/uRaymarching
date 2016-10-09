using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

[ExecuteInEditMode]
public class RaymarchingRenderer : MonoBehaviour
{
    Dictionary<Camera, CommandBuffer> cameras_ = new Dictionary<Camera, CommandBuffer>();
    Mesh quad_;

    [SerializeField] Material material = null;
    [SerializeField] CameraEvent pass = CameraEvent.BeforeGBuffer;

    Mesh GenerateQuad()
    {
        var mesh = new Mesh();
        mesh.vertices = new Vector3[4] {
            new Vector3( 1.0f , 1.0f,  0.0f),
            new Vector3(-1.0f , 1.0f,  0.0f),
            new Vector3(-1.0f ,-1.0f,  0.0f),
            new Vector3( 1.0f ,-1.0f,  0.0f),
        };
        mesh.triangles = new int[6] { 0, 2, 1, 2, 0, 3 };
        return mesh;
    }

    void CleanUp()
    {
        foreach (var pair in cameras_) {
            var camera = pair.Key;
            var buffer = pair.Value;
            if (camera) {
                camera.RemoveCommandBuffer(pass, buffer);
            }
        }
        cameras_.Clear();
    }

    void OnEnable()
    {
        CleanUp();
    }

    void OnDisable()
    {
        CleanUp();
    }

    void OnWillRenderObject()
    {
        UpdateCommandBuffer();
    }

    void UpdateCommandBuffer()
    {
        var act = gameObject.activeInHierarchy && enabled && material;
        if (!act) {
            OnDisable();
            return;
        }

        var camera = Camera.current;
        if (!camera || cameras_.ContainsKey(camera)) return;

        if (!quad_) quad_ = GenerateQuad();

        var buffer = new CommandBuffer();
        buffer.name = "Raymarching";
        buffer.DrawMesh(quad_, Matrix4x4.identity, material, 0, 0);
        camera.AddCommandBuffer(pass, buffer);
        cameras_.Add(camera, buffer);
    }
}
