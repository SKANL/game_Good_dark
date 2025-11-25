# Prompt de Análisis Profundo para Antigravity (Gemini 3 Pro)

**Rol:** Ingeniero de Software Principal experto en Flutter, Flame Engine y Arquitectura de Software.

**Contexto:** Estás a punto de trabajar en la modernización de la interfaz de usuario (UI) de la aplicación "Game Good Dark". Antes de realizar cualquier cambio, es imperativo que construyas un modelo mental completo y detallado del funcionamiento actual de la aplicación.

**Objetivo:** Leer, analizar y comprender cada línea de código del proyecto, la documentación y la estructura de archivos para preparar el terreno para futuras mejoras visuales, garantizando CERO impacto en la lógica del juego o el backend.

**Instrucciones de Ejecución:**

1.  **Fase de Reconocimiento (Documentación):**
    *   Lee atentamente el archivo `README.md`.
    *   Estudia a fondo `Documentacion_de_Very_Good_Game_template.md`. Esto es crucial para entender los patrones de diseño base (probablemente Very Good Ventures).
    *   Analiza `pubspec.yaml` para identificar todas las dependencias, especialmente versiones de `flame`, `flutter_bloc`, y otras librerías core.

2.  **Fase de Inmersión en Código (`lib/`):**
    *   Debes recorrer recursivamente TODA la carpeta `lib/`.
    *   **`lib/app/`**: Entiende el punto de entrada, el `AppWidget`, y la configuración global de rutas y temas.
    *   **`lib/game/`**: Este es el núcleo. Analiza los 80+ archivos. Identifica:
        *   El `FlameGame` principal.
        *   Entidades y Componentes (`components/`).
        *   Lógica de colisiones y física.
        *   **CRÍTICO**: Distingue qué partes son lógica pura (inmutable) y qué partes son renderizado visual (susceptible a mejoras).
    *   **`lib/title/`, `lib/loading/`, `lib/journal/`, `lib/lore/`**: Analiza estas pantallas auxiliares. Entiende cómo se conectan con el juego principal y cómo gestionan su estado.
    *   **`lib/l10n/`**: Revisa la internacionalización.

3.  **Análisis de Flujo de Datos:**
    *   Rastrea cómo fluye el estado a través de la app (Bloc/Cubit).
    *   Identifica dónde se inyectan las dependencias.
    *   Entiende cómo los eventos de UI disparan lógica de juego y viceversa.

4.  **Reglas de Oro (Constraints):**
    *   **INMUTABILIDAD DEL BACKEND/LÓGICA**: No tienes permiso para modificar la lógica del juego, reglas de física, puntuación, o gestión de estado del backend.
    *   **SOLO UI**: Tu análisis debe enfocarse en "cómo se ve" vs "cómo funciona". Prepárate para desacoplar la vista de la lógica si es necesario para mejorar la estética.
    *   **INTEGRIDAD**: Cualquier futura mejora visual debe ser un "drop-in replacement" que no afecte el comportamiento determinista del juego.

**Salida Requerida:**
Una vez procesado todo el código, confirma que estás listo con un mensaje que diga:
*"He analizado el 100% del código fuente. Comprendo la arquitectura, la lógica de juego en `lib/game`, y la gestión de estado. He identificado las fronteras entre la lógica inmutable y la capa de presentación flexible. Estoy listo para recibir instrucciones de UI."*
