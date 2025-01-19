using UnityEngine;

public class FullscreenShader : MonoBehaviour
{
    [SerializeField]
    Material fullscreenMaterial;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (fullscreenMaterial != null)
        {
            Graphics.Blit(source, destination, fullscreenMaterial);
        }
        else
        {
            Graphics.Blit(source, destination); // Renderiza normalmente se o material não está definido
        }
    }
}
