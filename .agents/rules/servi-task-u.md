---
trigger: always_on
---

# SERVI TASK — Guía de Estilo y Reglas de Diseño

Documento de referencia visual y estructural para la aplicación ServiTask. Toda nueva pantalla, componente o flujo debe seguir estas directrices para mantener coherencia de marca en los roles: **client**, **tasker** y **admin**.

---

## 1. Identidad Visual y Concepto

ServiTask es una plataforma de intermediación de servicios del hogar en Ecuador. El diseño debe transmitir **confianza, modernidad y profesionalismo**, sin perder calidez humana. El sistema de diseño se basa en la filosofía *Architectural Editorial*: cada pantalla debe sentirse como una página de una publicación de diseño de alto nivel — limpia, estructurada y con movimiento intencional.

- **Enfoque:** Mobile-First.
- **Estética:** Asimetría intencional, superficies en capas, sin líneas divisorias explícitas, glassmorfismo en elementos flotantes.
- **Regla de Oro:** Los límites se definen mediante cambios de color de fondo, nunca con bordes de 1px sólidos.

---

## 2. Paleta de Colores

### Colores Principales
- **Primary:** `#1A6BFF` — Azul de acción. Botones CTA, estados activos, badges destacados.
- **Primary Dark:** `#0053D3` — Variante oscura para gradientes y estados pressed.
- **Background:** `#F8F9FB` — Base general de la app.

### Superficies (Surface Hierarchy)
- **surface-container-lowest:** `#FFFFFF` — Cards y componentes flotantes.
- **surface-container-low:** `#F2F4F6` — Secciones secundarias, fondos de listas.
- **surface-container-highest:** `#E1E2E4` — Énfasis sutil, inputs en estado default.

### Texto
- **on-surface:** `#191C1E` — Títulos y textos de máxima autoridad.
- **on-surface-variant:** `#424655` — Body text, descripciones, metadatos.
- **outline-variant:** `#C2C6D8` — Ghost border (solo al 15% de opacidad).

### Colores de Estado
- **Éxito / Completado:** `#22C55E`
- **Alerta / Pendiente:** `#F59E0B`
- **Error / Cancelado:** `#EF4444`
- **En Disputa:** `#7C3AED`
- **Verificado (KYC):** `#1A6BFF` con badge de check.

### Regla "No-Line"
Prohibido usar bordes `1px solid` para separar secciones o contener elementos. Usar exclusivamente cambios de `surface-container`. Si la accesibilidad lo requiere, usar `outline-variant` al **15% de opacidad** máximo (ghost border).

### Regla "Glass & Gradient"
- **Elementos flotantes** (modals, bottom sheets, Floating Progress Orb): `surface` al 80% de opacidad + `backdrop-blur: 20px`.
- **CTA primarios** (botón Contratar, Publicar Tarea, Confirmar Pago): gradiente lineal de `#0053D3` a `#1A6BFF` a 135°.

---

## 3. Tipografía

Fuente única: **Inter Medium (500)** en todo el sistema. La jerarquía se construye únicamente con escala y contraste de color.

| Rol | Peso | Color | Uso en ServiTask |
|-----|------|-------|-----------------|
| Display Lg/Md/Sm | Medium 500 | `#191C1E` | Hero de onboarding, pantalla de bienvenida |
| Headline | Medium 500 | `#191C1E` | Nombre del tasker, título de tarea, precio acordado |
| Body Lg/Md | Medium 500 | `#424655` | Descripciones de servicio, bios de tasker, mensajes de chat |
| Body Sm | Medium 500 | `#424655` | Metadatos, timestamps, referencias de pago |
| Label Md/Sm | Medium 500 | Contextual | Tags de categoría, estado de tarea, tier del tasker |

- **Letter-spacing en Headlines:** `-0.02em` para acabado editorial de alto nivel.
- **Prohibido:** pesos Regular (400) y Bold (700). Solo Medium. Nunca mezclar pesos.

---

## 4. Elevación y Profundidad

Jerarquía visual mediante **capas tonales**, no sombras estructurales.

- **Principio de Capas:** Card en `#FFFFFF` sobre fondo `#F2F4F6` crea "soft lift" arquitectónico.
- **Ambient Shadow** (para acciones primarias flotantes): `blur: 24–40px`, `opacity: 6%`, color `#191C1E`.
- **Prohibido:** drop-shadows clásicos `(0, 2, 4, 0)`. Se perciben anticuados.

---

## 5. Componentes Clave

### A. Botones
- **Primario:** Gradiente `#0053D3→#1A6BFF` 135°, `border-radius: 14px`, texto `#FFFFFF` Inter Medium. Altura mínima 48px (touch-friendly).
- **Secundario:** Fondo `surface-container-high`, sin borde, texto `#1A6BFF`. Para acciones como "Ver perfil", "Editar tarea".
- **Terciario:** Fondo transparente, texto `#1A6BFF`. Para acciones de bajo peso como "Cancelar", "Ver más".

### B. Cards y Listas
- **Rounding:** `border-radius: 14px` en todas las cards. Firma visual "Soft Modern".
- **Separación de ítems:** `gap: 1.5rem (24px)` vertical. Sin dividers ni líneas.
- Si se requiere distinción visual, cambiar fondo del ítem a `#F2F4F6`.
- **Aplicaciones:** Card de tasker disponible, card de tarea activa, card de historial de pago, resumen de ganancias ("Mi Negocio").

### C. Inputs
- **Default:** Fondo `#E1E2E4`, sin borde visible.
- **Active/Focus:** Ghost border con `#1A6BFF` al 20% de opacidad.
- **Error:** Ghost border con `#EF4444` al 20% de opacidad.
- **Contextos:** Búsqueda de servicios, descripción de tarea, chat, datos bancarios del tasker.

### D. Badges y Tags de Estado
Usar `label-sm` Inter Medium. Nunca bordes sólidos.

| Estado task_status | Color fondo | Color texto |
|--------------------|------------|-------------|
| published | `#1A6BFF` 10% | `#1A6BFF` |
| confirmed / in_progress | `#22C55E` 10% | `#22C55E` |
| pending_review | `#F59E0B` 10% | `#F59E0B` |
| completed | `#E1E2E4` | `#424655` |
| cancelled | `#EF4444` 10% | `#EF4444` |
| disputed | `#7C3AED` 10% | `#7C3AED` |

### E. Floating Progress Orb (Componente ServiTask)
Indicador flotante de estado para tareas activas (`in_progress`). Glassmorphism: `surface` 80% + `backdrop-blur: 20px`. Ambient shadow 6%. Muestra: avatar del tasker, estado actual, countdown al deadline. No bloquea el contenido principal. Posición: esquina inferior derecha.

### F. Navegación Inferior (Bottom Nav)
- Máximo 4 iconos. Icono activo en `#1A6BFF`, inactivos en `#424655`.
- **Client:** Inicio · Mis Tareas · Chat · Perfil
- **Tasker:** Explorar · Mi Agenda · Chat · Mi Negocio
- Barra superior: título alineado a la izquierda, botón "atrás" minimalista.

### G. Verificación KYC (Flujo Tasker)
El estado de `verification_status` debe comunicarse visualmente con claridad:
- `pending`: badge Amber + icono de reloj.
- `verified`: badge Verde + icono de check con `#1A6BFF` en el avatar.
- `rejected`: banner de error con `#EF4444` y CTA para resubir documentos.
- `suspended`: estado bloqueante con modal glassmorphism explicativo.

---

## 6. Iconografía

- **Librería:** Lucide React o Phosphor Icons.
- **Estilo:** Outline, trazo 2px.
- **Regla:** Siempre acompañados de texto o en contextos inequívocos.
- **Contextos específicos:** ícono de wrench (Reparaciones), broom (Limpieza), car (Automotriz), cpu (Tecnología), tree (Exteriores), hard-hat (Construcción), book-open (Clases).
- **KYC:** shield-check para taskers verificados. star para tier `platinum`.

---

## 7. Layout y Espaciado

- **Márgenes laterales asimétricos** (editorial): `24px` izquierda, `32px` derecha en pantallas de detalle.
- **Pantallas de listas:** `px-4 (16px)` simétrico para máxima densidad de contenido.
- **Escala de espaciado:** 4px, 8px, 12px, 16px, 24px, 32px, 48px.
- **Regla de respiración:** Si un contenedor se siente lleno, subir un nivel de spacing (ej: de 16px a 24px). Nunca comprimir elementos para "caber más".
- **Separación de ítems en lista:** 12px mínimo, 24px preferido. Sin dividers.

---

## 8. Reglas de UX

- **Feedback Inmediato:** Toda acción (postular a tarea, confirmar inicio, liberar pago) debe mostrar cambio de estado visual o toast de confirmación.
- **Jerarquía de Precios:** `agreed_price` y `total_price` deben destacar visualmente sobre la descripción. Usar Display Md en `#191C1E`.
- **Trust Fee:** Mostrar siempre el desglose `platform_fee` vs `tasker_payout` con transparencia. Nunca ocultar la comisión.
- **Estados vacíos:** Pantallas sin tareas, sin taskers disponibles o sin mensajes deben tener empty states con ilustración minimalista y CTA claro.
- **Imágenes de tarea** (photos_before/after): Aspect ratio 4:3, `border-radius: 14px`, overlay oscuro sutil si llevan texto encima.
- **Botón de pánico** (safety_reports): Siempre accesible, nunca enterrado. Ícono de shield en rojo `#EF4444`, posición consistente en header durante tareas activas.
- **Tier del Tasker:** Mostrar badge de tier (`new`/`standard`/`pro`/`platinum`) junto al nombre. `platinum` usa gradiente `#0053D3→#1A6BFF`.

---

## 9. Do's y Don'ts

### Do ✓
- Usar Inter Medium en todo. El peso único crea firma visual consistente.
- Definir espacios con cambios de `surface-container`, nunca con líneas.
- Glassmorphism en modals, bottom sheets y Floating Progress Orb.
- Gradiente 135° en todos los CTAs primarios.
- Márgenes asimétricos en layouts editoriales (detalle de tasker, detalle de tarea).
- Mostrar `average_rating`, `tier` y `total_tasks_completed` juntos en la card del tasker.
- `border-radius: 14px` en todas las cards sin excepción.

### Don't ✗
- No usar bordes `1px solid` en ningún contexto.
- No usar pesos Regular (400) ni Bold (700).
- No usar drop-shadows clásicos `box-shadow: 0 2px 4px`.
- No agrupar elementos sin espacio de respiración. Si está lleno, ampliar spacing.
- No usar más de 2 niveles de jerarquía tipográfica en una misma card.
- No ocultar el estado de verificación KYC del tasker al cliente.
- No usar colores de estado (verde, rojo, amber) para decoración. Solo para semántica.

---

## 10. Glosario de Estados Visuales

| Contexto | Color | Componente |
|----------|-------|-----------|
| Tarea activa / en progreso | `#22C55E` | Badge + Orb flotante |
| Pago retenido en escrow | `#F59E0B` | Badge en card de pago |
| Disputa abierta | `#7C3AED` | Banner de alerta |
| Tasker verificado (KYC) | `#1A6BFF` | Shield-check en avatar |
| Emergencia / safety report | `#EF4444` | Botón de pánico en header |
| Tasker platinum | Gradiente `#0053D3→#1A6BFF` | Badge de tier |