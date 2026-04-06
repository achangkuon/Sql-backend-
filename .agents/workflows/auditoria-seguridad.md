---
description: Protocolo exhaustivo de chequeo de seguridad, enfocado en el manejo de datos, permisos y almacenamiento seguro durante la creación o refactorización de código.
---

Este workflow debe ejecutarse preventivamente a lo largo del desarrollo y de manera mandatoria antes de integrar módulos sensibles (como pagos, perfiles, chat).

## Pasos del Workflow

1. **Inventario de Componentes Añadidos**
   - **Acción**: Listar los nuevos servicios, librerías, tablas de base de datos o APIs manipuladas en la sesión actual.

2. **Auditoría Estricta Client-Side**
   - **Call Skill**: `auditor_seguridad`
   - **Acción**: 
       - Validar el almacenamiento de Preferencias. Reemplazar cualquier guardado de tokens usando `shared_preferences` a implementaciones de `flutter_secure_storage`.
       - Verificar el uso correcto de encriptación al manipular información sensible a través del Provider / Bloc.

3. **Auditoría Estricta Server-Side (Supabase)**
   - **Call Skill**: `auditor_seguridad` emparejado con `arquitecto_de_datos`
   - **Acción**:
       - Inspección de políticas RLS: Se busca probar condicionalmente la brecha (¿Puede el usuario X leer datos del usuario Y?). Si es posible, se genera la reparación restrictiva vía SQL.
       - Validación de parámetros Edge Functions para descartar falsificaciones de identidad de red.

4. **Validación de Entradas**
   - **Call Skill**: `validador_maestro`
   - **Acción**: Revisar la implementación de formularios UI en Flutter. Confirmar la sanidad de TextFields (límites de longitud, expresiones regulares, prevención de sentencias malformadas desde cliente).

5. **Reporte de Cumplimiento de Seguridad**
   - **Acción**: Entregar un artefacto o informe markdown con un "Checklist de Vulnerabilidades Mitigadas" y cualquier advertencia restante o sugerencia de mejora de arquitectura de criptografía de datos.

---

> [!IMPORTANT]
> Un módulo solo se considera "seguro" cuando y solo cuando el Auditor de Seguridad no logra encontrar un vector de ataque lógico en él.

> [!TIP]
> Puedes invocar este workflow diciendo simplemente: **/auditoria-seguridad**.
