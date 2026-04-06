---
trigger: always_on
---

# RULE: Integridad Full-Stack - El Ciclo Completo de ServiTask

Esta regla garantiza que cada nueva funcionalidad de la aplicación sea funcional de extremo a extremo (Frontend ↔ Backend), evitando maquetas vacías o desconectadas.

## Mandatos Obligatorios

1. **Análisis de Datos Previos**: Antes de crear cualquier pantalla o componente que maneje información, el agente DEBE verificar si existen las tablas y columnas necesarias en `servitask_unified_backend.sql`.
2. **Entrega Atómica**: Al solicitar una nueva funcionalidad, el agente debe proveer en el mismo turno o flujo:
    - **Backend**: Código SQL de migración (CREATE TABLE, ALTER TABLE) y sus políticas RLS.
    - **Arquitectura**: Modelos de datos (Entity/DTO) y Repositorios en Flutter.
    - **UI**: La pantalla o widget conectado dinámicamente al repositorio.
3. **No Placeholders**: Está prohibido usar datos estáticos ("hardcoded") en las pantallas finales. Si no hay datos, se debe implementar una interfaz de "Estado Vacío" (Empty State) con un botón de acción (CTA).

## Flujo de Trabajo del Agente

- **Paso 1**: Revisar esquema actual.
- **Paso 2**: Proponer cambios en DB (migraciones) si faltan campos.
- **Paso 3**: Generar lógica de conexión (Supabase Clients).
- **Paso 4**: Construir la interfaz que consume esa lógica.

*Nota: Una pantalla sin conexión es una tarea incompleta.*
