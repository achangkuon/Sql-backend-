---
description: Proceso estructurado para la creación o modificación de componentes y funcionalidades en ServiTask.
---

Este workflow coordina las habilidades especializadas para asegurar que cada cambio en la aplicación cumpla con los estándares de diseño editorial y seguridad de base de datos.

## Pasos del Workflow

1. **Analizar Petición**
   - **Acción**: Identificar si el requerimiento es un cambio de UI, lógica de Backend o ambos.
   - **Referencia**: Consultar `servi-task-u.md` y `sql-reference.md`.

2. **Estructurar Datos**
   - **Call Skill**: `arquitecto_de_datos`
   - **Objetivo**: Generar esquemas Supabase, tablas, índices y políticas RLS si el requerimiento lo exige.
   - **Validación**: Asegurar consistencia de tipos UUID y TIMESTAMPTZ.

3. **Diseñar Interfaz y Lógica**
   - **Call Skill**: `artesano_de_interfaz`
   - **Objetivo**: Crear pantallas o componentes en Flutter siguiendo la "Arquitectura Editorial".
   - **Restricción**: NUNCA usar bordes de 1px ni pesos tipográficos distintos a Inter Medium.

4. **Validación Maestro (QA)**
   - **Call Skill**: `validador_maestro`
   - **Acción**: Realizar un escaneo de cumplimiento estricto sobre el código generado.
   - **Salida**: Reporte de errores visuales o de seguridad y sugerencia de correcciones.

5. **Entrega y Confirmación**
   - **Acción**: Mostrar el resultado al usuario y pedir confirmación para aplicar los cambios o realizar ajustes.

---

> [!TIP]
> Puedes invocar este workflow diciendo simplemente: **/generar-modulo [tu requerimiento]**.
