---
description: Proceso estandarizado para preparar, validar y empaquetar ServiTask para su despliegue a tiendas de aplicaciones y producción.
---

Este workflow asegura que la aplicación esté lista para el usuario final, ejecutando revisiones de seguridad, depuración y empaquetado optimizado, coordinando los esfuerzos del equipo virtual.

## Pasos del Workflow

1. **Escaneo de Vulnerabilidades**
   - **Call Skill**: `auditor_seguridad`
   - **Acción**: Realizar el análisis de la gestión de secretos (que no haya IPs quemadas en código, contraseñas, etc.) y revisar que toda configuración sensible utilice variables de entorno firmes (`.env` o `--dart-define`).

2. **Revisión de Integridad de Base de Datos**
   - **Call Skill**: `arquitecto_de_datos`
   - **Acción**: Validar el estado de las migraciones de Supabase. Chequear agresivamente que TODAS las tablas de producción cuenten con RLS activo y que todos los Edge Functions tengan correctamente configuradas sus validaciones de JWT.

3. **Análisis Estático y QA UI**
   - **Call Skill**: `validador_maestro`
   - **Acción**: Ejecutar confirmación de la consistencia visual y de código. Aquí el agente te sugerirá y ayudará a correr `dart analyze` y asegurar la resolución de problemas (lints). Asegurar que no hayan `debugPrints` residuales en el repositorio.

4. **Configuración y Empaquetado (Build)**
   - **Call Skill**: `ingeniero_devops`
   - **Acción**: Preparar comandos de build definitivos. 
   - **Para Android**: Generar App Bundle (`.aab`) con la orden adecuada incluyendo ofuscación. Verificación de `key.properties`.
   - **Para iOS**: Proponer los pasos de firma en Xcode y revisión en el entorno local (CocoaPods check).

5. **Aprobación de Despliegue**
   - **Acción**: Mostrar al humano los archivos compilados resultantes (paths) y el check list superado para que proceda a subir a Google Play Console o App Store Connect.

---

> [!WARNING]
> Nunca ejecutes un build de producción si los pasos de auditoría de seguridad y validación fallan.

> [!TIP]
> Puedes invocar este workflow diciendo simplemente: **/preparar-deploy**.
