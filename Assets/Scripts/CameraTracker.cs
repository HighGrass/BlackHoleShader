using UnityEngine;

[ExecuteInEditMode]
public class CameraTracker : MonoBehaviour
{
    [SerializeField]
    Vector3 additionalVector;

    [SerializeField]
    Transform target;

    void Update()
    {
        transform.rotation =
            Quaternion.LookRotation(transform.position - target.position)
            * Quaternion.Euler(additionalVector);
    }
}
