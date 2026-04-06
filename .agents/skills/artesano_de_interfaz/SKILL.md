# Artesano de Interfaz - Digital Editorial Designer

Este skill se especializa en la creación de interfaces de usuario para la aplicación ServiTask en Flutter y React Native. Su firma visual es la "Arquitectura Editorial", un diseño de alta gama que prioriza la legibilidad, las capas y la asimetría intencional.

## Reglas de Oro Visuales (`servi-task-u.md`)

1. **Jerarquía Tipográfica**: Usar ÚNICAMENTE `Inter Medium (500)`. La jerarquía se construye con escala (Display, Headline, Body) y opacidad/color, NUNCA con pesos como Bold o Thin.
2. **Sistema Sin Líneas**: Está TERMINANTEMENTE PROHIBIDO usar `border: 1px solid`. La separación de elementos se logra mediante cambios sutiles en el fondo (`surface-container-low` vs `surface-container-highest`) o espacios de respiración amplios.
3. **Elevación por Capas**: No usar sombras fuertes. Usar capas tonales (`#FFFFFF` sobre `#F2F4F6`) para crear "soft lift".
4. **Acabado Premium**: Todo botón primario lleva un gradiente manual de 135° de `#0053D3` a `#1A6BFF` y un `border-radius: 14px`.
5. **Glassmorfismo**: Para elementos flotantes (Orb de progreso, Modales), usar `opacity: 80%` y `backdrop-blur: 20px`.

## Instrucciones para el Agente

Al invocar este skill, debes:
- Interpretar el requerimiento visual aplicando la asimetría editorial (ej. márgenes laterales de 24px/32px).
- Generar el código de componentes personalizados (no usar Material default si rompe el estilo).
- Asegurarse de que cada color corresponda a los tokens definidos: `primary`, `on-surface`, `surface-container`, etc.
- Incluir micro-animaciones (smooth transitions) para que la app se sienta "viva".

## Ejemplo de uso interno

- **Entrada:** "Diseñar card de perfil del tasker."
- **Acción:** Crear un contenedor `#FFFFFF` con `radius: 14px`, avatar con badge de verificación KYC, nombre en `Headline Md`, tier en color contextual y estadísticas limpias sin líneas divisorias.
