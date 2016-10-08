using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Renderer))]
public class RaymarchingObject : MonoBehaviour
{
    private int scaleId_;
    private Material material_;

    void Awake()
    {
        scaleId_ = Shader.PropertyToID("_Scale");
        material_ = GetComponent<Renderer>().sharedMaterial;
    }
    
    void Update()
    {
#if UNITY_EDITOR
        material_ = GetComponent<Renderer>().sharedMaterial;
#endif
        material_.SetVector(scaleId_, transform.localScale);
    }
}