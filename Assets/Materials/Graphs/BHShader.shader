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
        _AccretionDiskNoise ("Accretion Disk Noise", Float) = 0.2
        _AccretionDiskBloomIntensity ("Accretion Disk Bloom Intensity", Float) = 0.0
        _AccretionDiskDopplerEffectIntensity ("Accretion Disk Doppler Effect Intensity", Float) = 1
        _BlackHoleRotationSpeed ("Black Hole Rotation Speed", Float) = 5
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
            //Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 rayOrigin : TEXCOORD1;
                float3 rayDirection : TEXCOORD2;
                float2 uv : TEXCOORD0;
            };

            float _SchwarzschildRadius;
            float _SpaceDistortion;
            fixed4 _AccretionDiskColor;
            float _AccretionDiskThickness;
            float _AccretionDiskInnerRadius; 
            float _AccretionDiskOuterRadius; 
            float _AccretionDiskNoise;
            float _AccretionDiskBloomIntensity;
            float _AccretionDiskDopplerEffectIntensity;
            float _BlackHoleRotationSpeed;
            fixed4 _BlackHoleColor;
            samplerCUBE _SkyCube;
            float _Steps;

            float ColorIntensity(float3 color) {
                return color.r + color.g + color.b;
            }
            
            float RandomRange(float2 seed, float min, float max) {
                float num = frac(cos(sin(dot(seed, float2(12.9898, 78.233)))) * 43758.5453);
                return lerp(min, max, num);
            }

            float CreateAccretionDisk(v2f i, float3 rayPos, float3 blackHolePos)
            {
                // Calcula a posição relativa ao buraco negro
                float3 relativePos = rayPos - blackHolePos;

                // Calcula a direção tangencial no plano XZ
                float3 tangentialDir = normalize(float3(-relativePos.z, 0, relativePos.x));

                // Aplica o efeito de rotação ao disco de acreção
                float rotationalEffect = _BlackHoleRotationSpeed * length(relativePos.xz); // Escala pela distância horizontal
                relativePos.xz += tangentialDir.xz * rotationalEffect;

                // Calcula a distância horizontal atualizada
                float horizontalDistance = length(relativePos.xz);

                // Verifica se está dentro do raio interno ou externo do disco
                if (horizontalDistance < _AccretionDiskInnerRadius || horizontalDistance > _AccretionDiskOuterRadius)
                    return 1.0; // Fora do disco, retorna uma distância alta

                // Calcula a altura relativa ao plano do disco
                return abs(relativePos.y) - _AccretionDiskThickness;
            }

            float3 ApplySpaceDistortion(v2f i, float3 rayPos, float3 rayDir, float3 blackHolePos, float distanceToSingularity)
            {
                // Calcula a distorção radial
                float lerpValue = pow(_SchwarzschildRadius / distanceToSingularity, _SpaceDistortion);
                float3 radialDir = normalize(blackHolePos - rayPos);
            
                // Calcula a direção tangencial (rotação no plano XZ)
                float3 relativePos = rayPos - blackHolePos;
                float3 tangentialDir = normalize(float3(-relativePos.z, 0, relativePos.x)); // Perpendicular no plano XZ
            
                // Mistura a direção radial com a direção tangencial, ponderada pela rotação
                float3 rotationalEffect = tangentialDir * _BlackHoleRotationSpeed;
            
                // Direção final combinando a distorção radial e o efeito rotacional
                float3 distortedDir = normalize(rayDir + lerpValue * (radialDir + rotationalEffect));
            
                return distortedDir;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                float3 rayDirection = normalize(worldPos - rayOrigin);
                o.uv = v.uv;
                o.rayOrigin = rayOrigin;
                o.rayDirection = rayDirection;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float stepSize = 0.05;
                float epsilon = 0.01;

                float3 rayPos = i.rayOrigin;
                float3 rayDir = i.rayDirection;
                float3 blackHolePos = float3(0, 0, 0);

                fixed4 lightAccumulation = fixed4(0, 0, 0, 0);

                for (int step = 0; step < _Steps; step++)
                {
                    float distanceToSingularity = distance(blackHolePos, rayPos);

                    // avança o fotão seguindo a distorcão
                    rayDir = ApplySpaceDistortion(i, rayPos, rayDir, blackHolePos, distanceToSingularity);
                    rayPos += rayDir * stepSize;

                    float sdfResult = CreateAccretionDisk(i, rayPos, blackHolePos);
                    float diskNoise = RandomRange(i.uv, -_AccretionDiskNoise, _AccretionDiskNoise);
                    if (sdfResult < epsilon + diskNoise)
                    {
                        float3 rayDist = rayPos - blackHolePos;

                        // Direção tangente no plano XZ
                        float3 diskDir = normalize(_BlackHoleRotationSpeed + 0.00001 * float3(-rayDist.z, 0, rayDist.x));

                        // Diferença angular absoluta entre o raio e a direção do disco
                        float angleDifference = dot(normalize(rayDir), diskDir); // [-1, 1]
                        float mappedDifference = (angleDifference + 1.0) * 0.5; // [0, 1]

                        float rotationLayer = lerp(0, 1, clamp(mappedDifference, 0, 1));

                        // Simular o desvio para azul ou vermelho com base na direção
                        float3 dopplerEffect = lerp(float3(0.0, 0.0, 1), float3(1, 0.0, 0.0), mappedDifference);

                        // Ajustar intensidade do efeito com a velocidade de rotação
                        dopplerEffect *= rotationLayer * _AccretionDiskDopplerEffectIntensity;
                        // Aplica o efeito Doppler (intensidade ajustada de um lado do disco)
                        //float dopplerEffect = 1.0 + directionMult * _AccretionDiskDopplerEffectIntensity * 0.1;

                        float colorIntensity = clamp((distanceToSingularity - _AccretionDiskInnerRadius) / (_AccretionDiskOuterRadius - _AccretionDiskInnerRadius), 0, 1);
                        lightAccumulation.rgb += _AccretionDiskColor.rgb * rotationLayer * (1 - colorIntensity); // Acumula cor do disco
                        
                        float distanceFromCenter = (1 - clamp((distanceToSingularity + distanceToSingularity * 0.2 - _AccretionDiskInnerRadius) / (_AccretionDiskOuterRadius - _AccretionDiskInnerRadius), 0, 1));
                         // aplica o bloom effect de acordo com a distância ao buraco negro
                        lightAccumulation.rgb += _AccretionDiskBloomIntensity * rotationLayer * distanceFromCenter;
                        lightAccumulation.rgb += dopplerEffect;
                        
                    }

                    // Aplica a cor do buraco negro apenas se não houver luz do disco acumulada
                    if (distanceToSingularity <= _SchwarzschildRadius)
                    {
                        if (distanceToSingularity <= _SchwarzschildRadius)
                            if (lightAccumulation.r == 0 && lightAccumulation.g == 0 && lightAccumulation.b == 0)
                                return _BlackHoleColor;
                    }

                    float cameraDistance = length(_WorldSpaceCameraPos - blackHolePos) * 1.05;
                    if (distanceToSingularity > cameraDistance)
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
