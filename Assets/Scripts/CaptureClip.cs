using UnityEngine;

public class CaptureClip
{
    public float Time { get; private set; }
    (Vector3, Vector3) Position;

    public CaptureClip(float time, (Vector3, Vector3) position)
    {
        Time = time;
        Position = position;
    }

    public Vector3 GetPositionInTime(float t)
    {
        return Vector3.LerpUnclamped(Position.Item1, Position.Item2, t);
    }
}
