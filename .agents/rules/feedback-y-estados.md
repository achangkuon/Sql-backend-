# RULE: Feedback de Usuario y Estados de Transición

Esta regla garantiza una experiencia de usuario (UX) fluida y profesional. La aplicación ServiTask NUNCA debe dejar al usuario en un estado de incertidumbre.

## Mandatos Obligatorios

1. **Estado de Carga (Loading)**: Toda acción que implique una llamada a red (API, Supabase) DEBE mostrar un indicador visual:
    - **Carga inicial**: Skeleton screens o shimmer.
    - **Acción puntual (Submit)**: Loader circular o deshabilitado del botón con spinner.
2. **Manejo de Errores (Error Handling)**: Siempre capturar excepciones (`try-catch`). Mostrar el mensaje de error de forma no intrusiva pero clara (ej: Snackbar rojo suave con mensaje descriptivo en español).
3. **Feedback de Éxito**: Al completar una tarea crítica (Pago liberado, Tarea publicada), se DEBE mostrar una animación o Snackbar de éxito (`#22C55E`).
4. **Validación de Inputs**: Antes de enviar cualquier formulario, validar los campos localmente. Mostrar errores bajo los inputs sin bordes, usando el texto de alerta contextual.

## Estándares de Diseño (UX/UI)

- **Interacción**: Los botones primarios deben cambiar su gradiente visual a un estado "disabled" si la carga está en progreso.
- **Empty States**: Si una lista (`Mis Tareas`) está vacía, no mostrar una pantalla en blanco. Mostrar un gráfico minimalista y un texto persuasivo.

*Nota: Una aplicación fluida es aquella que se comunica en cada paso.*
