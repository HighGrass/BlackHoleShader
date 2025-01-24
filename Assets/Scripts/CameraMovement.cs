using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public Transform CameraTarget;

    [SerializeField]
    float CameraSpeed = 1f;
    float ClipTime = 0f;
    int ClipIndex = 0;
    List<CaptureClip> clips = new List<CaptureClip>();

    void Start()
    {
        clips.Add(
            new CaptureClip(
                10,
                (new Vector3(-6.719f, -0.93f, 5.01f), new Vector3(3.059f, 0.689f, 8.26f))
            )
        );
        clips.Add(
            new CaptureClip(
                10,
                (new Vector3(12.63f, -4.9f, 1.679f), new Vector3(5.44f, 1.34f, 4.48f))
            )
        );
    }

    void Update()
    {
        if (clips.Count == 0)
            return;

        ClipTime += Time.deltaTime * CameraSpeed;

        if (ClipTime < clips[ClipIndex].Time)
        {
            CameraTarget.transform.position = clips[ClipIndex]
                .GetPositionInTime(ClipTime / clips[ClipIndex].Time);
        }
        else
        {
            if (clips.Count >= ClipIndex + 2)
                ClipIndex++;
            else
                ClipIndex = 0;

            ClipTime = 0f;
        }
    }
}
