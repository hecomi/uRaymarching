using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Renderer))]
public class RaymarchingObject : MonoBehaviour
{
    public enum Shape
    {
        Cube,
        Sphere,
        None,
    }

    [SerializeField] Shape shape = Shape.Cube;
    [SerializeField] Color gizmoColor = new Color(1f, 1f, 1f, 0.1f);
    [SerializeField] Color gizmoSelectedColor = new Color(1f, 0f, 0f, 1f);

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
        UpdateScale();
        UpdateShape();
    }

    void UpdateScale()
    {
        material_.SetVector(scaleId_, scale);
    }

    void UpdateShape()
    {
        switch (shape) {
            case Shape.Cube:
                material_.EnableKeyword("OBJECT_SHAPE_CUBE");
                material_.DisableKeyword("OBJECT_SHAPE_SPHERE");
                break;
            case Shape.Sphere:
                material_.EnableKeyword("OBJECT_SHAPE_SPHERE");
                material_.DisableKeyword("OBJECT_SHAPE_CUBE");
                break;
            default:
                break;
        }
    }

    void OnDrawGizmos()
    {
        DrawGizmos(gizmoColor);
    }

    void OnDrawGizmosSelected()
    {
        DrawGizmos(gizmoSelectedColor);
    }

    void DrawGizmos(Color color)
    {
        Gizmos.color = color;
        Gizmos.matrix = Matrix4x4.identity * transform.localToWorldMatrix;
        switch (shape) {
            case Shape.Cube:
                Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
                break;
            case Shape.Sphere:
                Gizmos.DrawWireSphere(Vector3.zero, 0.5f);
                break;
            case Shape.None:
                break;
        }
    }
}