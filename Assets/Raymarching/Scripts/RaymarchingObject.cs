using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Renderer))]
public class RaymarchingObject : MonoBehaviour
{
    private int scaleId_;
    private Material material_;
    private Vector3 scale
    {
        get 
        { 
            var s = transform.localScale;
            return new Vector3(Mathf.Abs(s.x), Mathf.Abs(s.y), Mathf.Abs(s.z)); 
        }
    }

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
        material_.SetVector(scaleId_, scale);
    }
}