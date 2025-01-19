Shader "Custom/BHShader"
{
    Properties
    {
        _SchwarzschildRadius ("Schwarzschild Radius", Float) = 0.5
        _SpaceDistortion ("Space Distortion", Float) = 2.0
        _AccretionDiskColor ("Accretion Disk Color", Color) = (1, 0.5, 0, 1)
        _AccretionDiskThickness ("Accretion Disk Thickness", Float) = 0.1
        _AccretionDiskInnerRadius ("Accretion Disk Inner Radius", Float) = 1.0 
        _AccretionDiskOuterRadius ("Accretion Disk Outer Radius", Float) = 5.0 
        _BlackHoleColor ("Black Hole Color", Color) = (0, 0, 0, 1)
        _SkyCube ("Skybox Texture", Cube) = "" {}
        _Steps ("Steps", Float) = 1000
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            Cull Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 rayOrigin : TEXCOORD1;
                float3 rayDirection : TEXCOORD2;
            };

            float _SchwarzschildRadius;
            float _SpaceDistortion;
            fixed4 _AccretionDiskColor;
            float _AccretionDiskThickness;
            float _AccretionDiskInnerRadius; 
            float _AccretionDiskOuterRadius; 
            fixed4 _BlackHoleColor;
            samplerCUBE _SkyCube;
            float _Steps;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                float3 rayDirection = normalize(worldPos - rayOrigin);

                o.rayOrigin = rayOrigin;
                o.rayDirection = rayDirection;
                return o;
            }

            float createAccretionDisk(float3 rayPos, float3 blackHolePos)
            {
                float3 relativePos = rayPos - blackHolePos;
                float horizontalDistance = length(relativePos.xz);

                // Verifica se está dentro do raio interno ou externo do disco
                if (horizontalDistance < _AccretionDiskInnerRadius || horizontalDistance > _AccretionDiskOuterRadius)
                    return 1.0; // Fora do disco, retorna uma distância alta

                // altura do disco
                return abs(relativePos.y) - _AccretionDiskThickness;
            }

            float3 applySpaceDistortion(float3 rayPos, float3 rayDir, float3 blackHolePos, float distanceToSingularity)
            {
                float lerpValue = pow(_SchwarzschildRadius / distanceToSingularity, _SpaceDistortion);
                float3 affectedDir = normalize(blackHolePos - rayPos);
                return normalize(lerp(rayDir, affectedDir, lerpValue));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                const int maxSteps = _Steps;
                float stepSize = 0.05;
                float epsilon = 0.01;

                float3 rayPos = i.rayOrigin;
                float3 rayDir = i.rayDirection;
                float3 blackHolePos = float3(0, 0, 0);

                fixed4 lightAccumulation = fixed4(0, 0, 0, 0);

                for (int step = 0; step < maxSteps; step++)
                {
                    float distanceToSingularity = distance(blackHolePos, rayPos);

                    bool isFront = rayPos.z > blackHolePos.z;

                    // Parte frontal do disco
                    if (isFront)
                    {
                        float sdfResult = createAccretionDisk(rayPos, blackHolePos);
                        if (sdfResult < epsilon)
                        {
                            lightAccumulation.rgb += _AccretionDiskColor.rgb; // Acumula cor do disco frontal
                            lightAccumulation.a = 1.0;
                        }
                    }

                    // avança o fotão seguindo a distorcão
                    rayDir = applySpaceDistortion(rayPos, rayDir, blackHolePos, distanceToSingularity);
                    rayPos += rayDir * stepSize;

                    // Parte traseira do disco
                    if (!isFront)
                    {
                        float sdfResult = createAccretionDisk(rayPos, blackHolePos);
                        if (sdfResult < epsilon)
                        {
                            lightAccumulation.rgb += _AccretionDiskColor.rgb; // Acumula cor do disco traseiro
                            lightAccumulation.a = 1.0;
                        }
                    }

                    // Aplica a cor do buraco negro apenas se não houver luz do disco acumulada
                    if (distanceToSingularity <= _SchwarzschildRadius)
                    {
                        if (lightAccumulation.r == 0 && lightAccumulation.g == 0 && lightAccumulation.b == 0)
                        {
                            return _BlackHoleColor;
                        }
                    } 

                    if (distanceToSingularity > _Steps)
                        break;
                }

                float distanceToSingularity = distance(blackHolePos, rayPos);
                float gradientFactor = saturate((distanceToSingularity - _SchwarzschildRadius) / 
                                                (_AccretionDiskOuterRadius - _SchwarzschildRadius));

                // Mistura a cor do buraco negro com o fundo usando o gradiente
                float3 skyColor = texCUBE(_SkyCube, rayDir).rgb * 10.0;
                float3 finalColor = lerp(_BlackHoleColor.rgb, skyColor, gradientFactor);

                // Adiciona a cor acumulada
                lightAccumulation.rgb = lightAccumulation.rgb + finalColor;
                lightAccumulation.a = 1.0;

                return lightAccumulation;
            }
            ENDCG
        }
    }
}
