using UnityEngine;

public class DebugCamera : MonoBehaviour
{
    [SerializeField] float speedXY         = 1f;
    [SerializeField] float speedXZ         = 5f;
    [SerializeField] float speedForward    = 10f;
    [SerializeField] float angleSpeed      = 10f;

    private Vector3 preMousePosition_;
    private Vector3 targetEuler_;
    private Vector3 targetPos_;

    void Start()
    {
        preMousePosition_ = Input.mousePosition;
        targetPos_ = transform.position;
        targetEuler_ = transform.rotation.eulerAngles;
    }

    void Update()
    {
        UpdateXY();
        UpdateXZ();
        UpdateForward();
        UpdateRotation();
        UpdateMousePosition();
        UpdateTransform();
    }

    void UpdateXY()
    {
        if (Input.GetMouseButton(2) && !Input.GetMouseButtonDown(2)) {
            var dPos = Input.mousePosition - preMousePosition_;
            var velocity = ((-transform.up) * dPos.y + (-transform.right) * dPos.x) * speedXY;
            targetPos_ += velocity * Time.deltaTime;
        }
    }

    void UpdateXZ()
    {
        var x = Input.GetAxisRaw("Horizontal");
        var z = Input.GetAxisRaw("Vertical");

        var velocity = Quaternion.AngleAxis(targetEuler_.y, Vector3.up) * (new Vector3(x, 0f, z)) * speedXZ;
        targetPos_ += velocity * Time.deltaTime;
    }

    void UpdateForward()
    {
        var x = Input.mouseScrollDelta.x;
        var z = Input.mouseScrollDelta.y;

        var velocity = (transform.forward * z + transform.right * x) * speedForward;
        targetPos_ += velocity * Time.deltaTime;
    }

    void UpdateRotation()
    {
        if ((Input.GetMouseButton(0) && !Input.GetMouseButtonDown(0)) ||
            (Input.GetMouseButton(1) && !Input.GetMouseButtonDown(1))) {
            var dPos = Input.mousePosition - preMousePosition_;
            targetEuler_ += new Vector3(-dPos.y, dPos.x, 0f) * Time.deltaTime * angleSpeed;
            targetEuler_.x = Mathf.Clamp(targetEuler_.x, -90f, 90f);
        }
    }

    void UpdateMousePosition()
    {
        preMousePosition_ = Input.mousePosition;
    }

    void UpdateTransform()
    {
        transform.position = Vector3.Lerp(transform.position, targetPos_, 0.5f);
        transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.Euler(targetEuler_), 0.5f);
    }
}
