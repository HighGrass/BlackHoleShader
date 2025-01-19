using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class BlackHoleEffect : MonoBehaviour
{
    //public settings
    public Shader shader;
    public Transform blackHole;
    public float ratio;
    public float radius;

    //private settings
    Camera cam;
    Material _material;

    Material material
    {
        get
        {
            if (_material == null)
            {
                _material = new Material(shader);
                _material.hideFlags = HideFlags.HideAndDontSave;
            }
            return _material;
        }
    }

    void OnEnable()
    {
        cam = GetComponent<Camera>();
        ratio = 1f / cam.aspect;
    }

    void OnDisable()
    {
        if (_material)
        {
            DestroyImmediate(_material);
        }
    }

    Vector3 wtsp;
    Vector2 pos;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (shader && material && blackHole)
        {
            wtsp = cam.WorldToScreenPoint(blackHole.position);

            if (wtsp.z > 0)
            {
                pos = new Vector2(wtsp.x / cam.pixelWidth, (wtsp.y / cam.pixelHeight));
                _material.SetVector("_BlackHoleCenter", blackHole.position);
                _material.SetFloat("_DistortionRadius", radius);
                _material.SetFloat("_DistortionStrength", Mathf.Clamp01(1.0f / (wtsp.z * wtsp.z)));
                _material.SetFloat("_DistortionFalloff", 2.0f); // Pode ser ajustado para suavizar o efeito.
                Debug.Log("Distance: " + wtsp.z);
                Graphics.Blit(source, destination, material);
            }
            else
            {
                Graphics.Blit(source, destination); // Sem efeito caso o buraco negro esteja atrás da câmera.
            }
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
