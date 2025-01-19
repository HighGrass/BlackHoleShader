# Shader de Buraco Negro no Unity

## Descrição Geral
Este projeto implementa um shader personalizado em Unity para simular o comportamento visual de um buraco negro utilizando conceitos de física computacional e gráficos avançados. O shader utiliza um modelo baseado em **Ray Marching** e **Space Distortion** para representar os efeitos gravitacionais e a interação de luz com o disco de acreção ao redor do buraco negro. A implementação captura a distorção do espaço-tempo e os efeitos ópticos derivados da Teoria da Relatividade Geral.

**Técnicas Implementadas**: Ray Marching e Distortion Effect.

---

## Fundamentos Científicos

1. **Buraco Negro: Schwarzschild Radius**  
   O buraco negro é definido pelo **raio de Schwarzschild**, o limite em que nada, nem mesmo a luz, pode escapar de sua gravidade. Este valor (__SchwarzschildRadius_) é um dos parâmetros centrais do shader e define a singularidade.

2. **Disco de Acreção**  
   A matéria orbitando o buraco negro forma um disco de acreção visível devido ao aquecimento intenso por fricção e compressão. Este disco foi simulado usando cálculos de distância e acumulando a cor (_AccretionDiskColor_) em regiões definidas entre os raios internos e externos.
pa
3. **Distorção do Espaço-Tempo**  
   A implementação leva em conta a distorção gravitacional do espaço-tempo, ajustando a direção dos raios (_applySpaceDistortion_). Este fenômeno é modelado matematicamente através da interpolação vetorial (_lerp_) entre a direção inicial do raio e a direção da singularidade, com intensidade proporcional à distância relativa.

---

## Descrição Técnica

### Implementação do Shader
O shader é definido em **HLSL** (High-Level Shader Language) e utiliza o modelo **Unlit** para gerenciar a renderização sem influência direta de luzes da cena. Tudo é desenhado na superfície de um plano que mantêm sempre um angulo perpendicular á camera. A implementação é composta por dois passos principais:

1. **Vertex Shader (`vert`)**  
   Calcula a origem e a direção dos raios para cada fragmento da tela, baseando-se na posição da câmera (_WorldSpaceCameraPos_) e na posição do objeto.

2. **Fragment Shader (`frag`)**  
   O fragment shader utiliza **Ray Marching** para calcular as interseções dos raios com o disco de acreção e a singularidade, acumulando cores baseadas nos seguintes fatores:
   - Distância ao buraco negro (efeito gravitacional)
   - Presença no disco de acreção (frontal e traseiro)
   - Proximidade do horizonte de eventos (raio de Schwarzschild)

### Parâmetros Configuráveis
Os seguintes parâmetros podem ser ajustados pelo usuário para personalizar a simulação:

- **_SchwarzschildRadius**: Define o raio da singularidade gravitacional.  
- **_AccretionDiskColor**: Cor do disco de acreção.  
- **_AccretionDiskThickness**: Altura do disco em relação ao eixo vertical.  
- **_AccretionDiskInnerRadius** e **_AccretionDiskOuterRadius**: Determinam os limites internos e externos do disco.  
- **_Steps**: Número máximo de passos para o algoritmo de Ray Marching, controlando a precisão.  

### Principais Funções
1. **`CreateAccretionDisk`**  
   Simula o disco de acreção determinando se um ponto no espaço (_rayPos_) está dentro do intervalo radial e da espessura vertical do disco. Retorna uma distância simulada para o disco.

2. **`ApplySpaceDistortion`**  
   Implementa a distorção do espaço-tempo em função da distância até a singularidade, alterando a direção do raio ao longo de sua trajetória.

3. **Ray Marching Loop**  
   Realiza iterações sucessivas para aproximar a trajetória do raio em direção ao buraco negro, acumulando cores do disco e do céu, ou retornando a cor do buraco negro caso o raio entre no horizonte de eventos.

---

## Resultados
O shader é capaz de simular visualmente os seguintes efeitos:

- **Distorção Gravitacional**: Desvio dos raios de luz ao redor do buraco negro.  
- **Disco de Acreção**: Representação distorcida do disco, com acumulação de luz e cores personalizáveis.  
- **Horizonte de Eventos**: A região escura correspondente ao horizonte de evetos é renderizada respeitando o raio de Schwarzschild.
  
![image](https://github.com/user-attachments/assets/966652c0-e40d-4c6f-8cdf-901e36a561ba)
![image](https://github.com/user-attachments/assets/ca540a61-fd79-4cbf-9170-fd445ec989ff)
![image](https://github.com/user-attachments/assets/34f6f816-76df-4b99-8ddd-6a0e2e540c96)
![image](https://github.com/user-attachments/assets/7725ddd9-c9c2-416c-bdaf-ce8d5f266e86)


---

## Pontos de Destaque
- **Ray Marching**  
  Foi utilizada uma abordagem iterativa com até 1000 passos (_Steps_) para aproximar as trajetórias dos raios em um espaço não linear. Aumentar este valor, permite visualizar o buraco negro de uma maior distância.

- **Integração de Skybox**  
  O shader incorpora uma textura cúbica (_SkyCube_) como fundo, ajustando dinamicamente o gradiente de transição entre o buraco negro e o espaço.

- **Efeito de Lente Gravitacional**  
  O espaço ao redor do buraco negro é distorcido usando interpolação entre direções, simulando a curvatura da luz prevista pela Relatividade Geral.

---

## Limitações
1. **Performance**  
   O uso de **Ray Marching** com um alto número de passos pode impactar negativamente a performance em dispositivos com menor capacidade de processamento.

2. **Modelagem Simplificada**  
   A distorção gravitacional foi implementada de forma aproximada, sem levar em conta todos os aspectos físicos da Teoria da Relatividade Geral.

3. **Interação Física**  
   Não foi considerada a emissão de luz relativística ou outros fenômenos avançados, como Doppler effect causado pela rotação de um buraco negro ou a Hawking radiation.

![image](https://github.com/user-attachments/assets/4387699a-54e1-4406-a234-8014706c955f)

---

## Bibliografia

- Videos das aulas de Computação Gráfica: https://www.youtube.com/@diogoandrade9588
- Raymaching: https://medium.com/dotcrossdot/raymarching-simulating-a-black-hole-53624a3684d3
- Raymaching: https://www.youtube.com/watch?app=desktop&v=S8AWd66hoCo&t=128s
- Accretion Disk: https://www.youtube.com/watch?v=zUyH3XhpLTo
- Accretion Disk: https://www.youtube.com/watch?v=VX8RbSC-Br4
- Gravitational Lensing: https://discussions.unity.com/t/gravitational-lensing-shader-help/714565
- Gravitational Distortion: https://github.com/SimonVanSchuylenbergh/Real-Time-Black-Hole-v2-public
---

## Conclusão
Este projeto demonstra com sucesso a aplicação de técnicas avançadas de computação gráfica, integrando fundamentos físicos e algoritmos eficientes para simular o comportamento visual de um buraco negro. Apesar das limitações, o resultado final é visualmente impactante e cientificamente consistente, tornando-o um excelente exemplo de como unir física e programação gráfica.
