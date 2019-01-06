using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections.Generic;

[ExecuteInEditMode]
public class RaymarchingRenderer : MonoBehaviour
{
    Dictionary<Camera, CommandBuffer> cameras_ = new Dictionary<Camera, CommandBuffer>();
    Mesh quad_;

    [SerializeField] Material material = null;
    [SerializeField] CameraEvent pass = CameraEvent.AfterGBuffer;
    CameraEvent pass_;

    Mesh CreateQuad()
    {
        var mesh = new Mesh();
        mesh.vertices = new Vector3[4] {
            new Vector3( 1f,  1f,  0f),
            new Vector3(-1f,  1f,  0f),
            new Vector3(-1f, -1f,  0f),
            new Vector3( 1f, -1f,  0f),
        };
        mesh.triangles = new int[6] { 0, 1, 2, 2, 3, 0 };
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();
        return mesh;
    }

    [ContextMenu("CleanUp")]
    void CleanUp()
    {
        foreach (var pair in cameras_) {
            var camera = pair.Key;
            var buffer = pair.Value;
            if (camera) {
                camera.RemoveCommandBuffer(pass_, buffer);
            }
        }
        cameras_.Clear();
    }

    void OnEnable()
    {
        CleanUp();
        pass_ = pass;
    }

    void OnDisable()
    {
        CleanUp();
    }

    void Update()
    {
        if (!gameObject.activeInHierarchy || !enabled || !material) {
            CleanUp();
            return;
        }

        if (pass != pass_) {
            CleanUp();
            pass_ = pass;
        }

        foreach (var camera in Camera.allCameras) {
            UpdateCommandBuffer(camera);
        }

#if UNITY_EDITOR
        foreach (SceneView view in SceneView.sceneViews) {
            if (view != null) {
                UpdateCommandBuffer(view.camera);
            }
        }
#endif
    }

    void UpdateCommandBuffer(Camera camera)
    {
        if (!camera || cameras_.ContainsKey(camera)) return;

        if (!quad_) quad_ = CreateQuad();

        var buffer = new CommandBuffer();
        buffer.name = "Raymarching";
        buffer.DrawMesh(quad_, Matrix4x4.identity, material, 0, 0);
        camera.AddCommandBuffer(pass, buffer);
        cameras_.Add(camera, buffer);
    }
}
