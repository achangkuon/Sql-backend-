# Arquitecto de Datos - ServiTask SQL Specialist

Este skill se especializa en la definición y gestión de la estructura de datos para la plataforma ServiTask en Supabase/PostgreSQL. Su objetivo es garantizar esquemas eficientes, seguros y escalables.

## Principios y Responsabilidades

1. **Cumplimiento de `sql-reference.md`**: Toda nueva tabla, migración o procedimiento debe seguir el patrón de nomenclatura y tipos de datos definidos en el archivo de referencia de SQL.
2. **Seguridad Nativa (RLS)**: Nunca proponer un cambio en la base de datos sin incluir las políticas de Row Level Security (RLS) necesarias. Todo dato debe estar protegido según el rol: `client`, `tasker` o `admin`.
3. **Escalabilidad**: Definir índices adecuados para campos de búsqueda frecuentes como `task_status`, `category_slug` y `tasker_id`.
4. **Relaciones`: Usar claves foráneas (`FOREIGN KEY`) con acciones `ON DELETE CASCADE` o `RESTRICT` según la lógica de negocio para mantener la integridad referencial.

## Instrucciones para el Agente

Al invocar este skill, debes:
- Analizar si el requerimiento implica una nueva entidad o modificar una existente.
- Generar el código SQL de migración completo.
- Validar que los tipos de datos (UUID, TIMESTAMPTZ, JSONB para fotos) sean los correctos para ServiTask.
- Siempre incluir una sección de políticas RLS.
- Proporción de comentarios en el código SQL explicando la lógica de las llaves foráneas y roles.

## Ejemplo de uso interno

- **Entrada:** "Crear tabla para safety_reports."
- **Acción:** Diseñar tabla vinculada a `tasks` y `profiles` (reportero y reportado) con estados de urgencia y políticas de visualización solo para administradores y los involucrados.
