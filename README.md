# Platform Fighter - TFG (Godot 4)

[![Godot Engine](https://img.shields.io/badge/Godot-4.x-blue?style=for-the-badge&logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/Language-GDScript-yellow?style=for-the-badge&logo=codeforces&logoColor=white)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)

Prototipo funcional de videojuego del subgénero *Platform Fighter* desarrollado como **Trabajo de Fin de Grado (TFG)**. El proyecto implementa un motor de combate bidimensional basado en componentes, un sistema de inteligencia artificial autónomo mediante percepción espacial por sensores (*RayCasts*), y una arquitectura modular desacoplada.

---

## Descarga Directa de Ejecutables
Puedes descargar la última versión compilada lista para jugar en tu sistema operativo:

* **[Descargar para Windows (juego.exe)](./juego.exe)**
* **[Descargar para Linux](./juego_linux)**

---

#🏛️ Características Técnicas Principales
* **Desacoplamiento de Controladores:** El núcleo del personaje actúa como una API agnóstica; un nodo selector externo inyecta dinámicamente el controlador humano (`player_controller.gd`) o de IA (`ai_controller.gd`) según la selección en el menú.
* **Inteligencia Artificial Autónoma (`AIController`):** Sistema de percepción espacial mediante `RayCast2D` para la detección en tiempo real de plataformas, bordes y abismos (`VOID_SAFE`, `VOID_DANGER`), con máquina de estados táctica.
* **Cámara Dinámica Multiobjetivo (`CameraBrawler`):** Cálculo continuo del centro de masas entre contendientes con interpolación lineal (`lerp`) y escalado de zoom adaptativo.
* **Optimización y Carga Asíncrona:** Uso de hilos independientes (`Threaded Loading`) para la transición fluida entre menús y la escena de combate sin bloqueos en el hilo principal.

---

## Requisitos e Instalación para Desarrollo
Si prefieres clonar el repositorio y ejecutar el proyecto directamente desde el editor de código:

1. Descarga e instala **[Godot Engine 4.x](https://godotengine.org/)** (versión recomendada 4.7 estable).
2. Clona este repositorio en tu máquina local:
   ```bash
   git clone [https://github.com/TU_USUARIO/TU_REPOSITORIO.git](https://github.com/TU_USUARIO/TU_REPOSITORIO.git)
