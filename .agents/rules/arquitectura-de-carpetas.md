# RULE: Arquitectura de Carpetas y Organización del Proyecto

Esta regla define la "fuente única de verdad" sobre dónde debe vivir cada archivo en el proyecto ServiTask. Mantener esta estructura permite la escalabilidad y facilita la búsqueda de errores.

## Estructura de Capas (Basada en DDD/Limpia)

1. **`lib/core`**: Configuraciones globales, temas de color (`servi-task-u.md`), utilidades de red y el cliente de Supabase Centralizado.
2. **`lib/models`**: Clases de datos inmutables que mapean la base de datos de Supabase. (Ej: `task_model.dart`, `profile_model.dart`).
3. **`lib/repositories`**: Lógica de interacción pura con Supabase API/Postgres. Deben ser clases que solo manejen datos y devuelvan `Future` o `Stream`.
4. **`lib/providers / lib/bloc`**: Gestión de estado. Controlan el flujo de datos entre la UI y los Repositorios.
5. **`lib/ui/screens`**: Pantallas de flujo completo (Home, Detalle de Tarea, Perfil, Onboarding).
6. **`lib/ui/components`**: Widgets atómicos, tarjetas de servicios y botones personalizados reutilizables.
7. **`lib/ui/layouts`**: Estructuras de página (Editorial Grids, Bottom Nav Bar, App Bars personalizadas).

## Mandatos Obligatorios

- **Separación de Concern**: No escribir lógica de Supabase/SQL dentro de los archivos de la UI (`Widget build`).
- **Nomenclatura**: Todo archivo debe usar `snake_case` (ej: `user_profile_screen.dart`). Si el archivo contiene una clase, esta debe ser `PascalCase` (`UserProfileScreen`).
- **No duplicar**: Si un componente se usa en más de 2 pantallas, DEBE moverse a `lib/ui/components`.

*Nota: Una arquitectura ordenada es la base para una construcción fluida.*
