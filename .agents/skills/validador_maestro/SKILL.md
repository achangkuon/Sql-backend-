# Validador Maestro - ServiTask QA & Compliance

Este skill funciona como un control de calidad crítico para la aplicación ServiTask. Es el responsable de validar que tanto el código de backend (SQL) como el de frontend (Flutter) cumplan rigurosamente con las reglas de estilo y seguridad del proyecto.

## Áreas de Auditoría

1. **Cumplimiento de Estilo UI**:
    - **Prohibido**: Bordes de `1px solid`.
    - **Prohibido**: Fuentes distintas a `Inter Medium`.
    - **Prohibido**: Sombras clásicas (`drop-shadow: 0 2px 4px`).
    - **Mandatorio**: `border-radius: 14px` en cards y botones.
    - **Mandatorio**: Gradientes 135° en CTAs primarios.

2. **Auditoría de Backend (SQL & RLS)**:
    - **Mandatorio**: Toda tabla nueva debe incluir políticas RLS (`ENABLE ROW LEVEL SECURITY`).
    - **Mandatorio**: Uso de tipos de datos consistentes (UUID para LLaves, TIMESTAMPTZ para fechas).
    - **Mandatorio**: Presencia de comentarios que expliquen la lógica de acceso por rol (`anon`, `authenticated`, `service_role`).

3. **Lógica de Estados**:
    - Verificar que los estados de tarea (`task_status`) cambien solo según las transiciones lógicas (ej: un `cancelled` no puede pasar a `completed`).

## Instrucciones para el Agente

Al invocar este skill, debes:
- Realizar un "escaneo" mental o de código del componente propuesto.
- Reportar errores visuales como "Detectado un borde sólido de 1px en la línea X. Se recomienda usar cambio de color de superficie."
- Sugerir correcciones inmediatas antes de que el usuario las pida.
- Validar accesibilidad básica (contraste de texto `#191C1E` sobre `#FFFFFF`).

## Ejemplo de uso interno

- **Entrada:** Escanear archivo `task_card.dart`
- **Acción:** Detectar inconsistencias como un `FontWeight.bold` y sugerir reemplazar por `Medium 500` con aumento de escala tipográfica.
