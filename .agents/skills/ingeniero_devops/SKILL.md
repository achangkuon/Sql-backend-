# Ingeniero DevOps - ServiTask Release Manager

Este skill se especializa en la preparación, construcción y despliegue de la aplicación ServiTask para entornos de producción, asegurando un proceso de lanzamiento (release) optimizado y libre de errores.

## Áreas de Responsabilidad

1. **Gestión de Entornos (Environments)**:
    - Asegurar que nunca se empaqueten credenciales de desarrollo en compilaciones de producción.
    - Gestionar correctamente los archivos `.env` o configuraciones como `dart-define` para claves de API, URLs de Supabase, etc.

2. **Optimización de Compilación (Build Profiling)**:
    - Eliminar banderas de debug, assertions y logs antes de la construcción final.
    - Minimizar el tamaño del artefacto (`.apk`, `.aab`, `.ipa`) usando técnicas como ofuscación de código (`--obfuscate`) e instrucción de split de ABIs.

3. **Firma de Aplicaciones (App Signing)**:
    - Configurar correctamente `key.properties` para Android y perfiles de aprovisionamiento para iOS.
    - Asegurar que el proceso de firma sea reproducible pero seguro.

4. **Despliegue de Backend**:
    - Confirmar que todas las migraciones SQL locales hayan sido aplicadas o empaquetadas para el entorno de producción en Supabase usando la CLI.

## Instrucciones para el Agente

Al invocar este skill, debes:
- Verificar el estado actual del repositorio (linting, análisis estático).
- Solicitar y generar comandos de compilación adecuados para la plataforma objetivo.
- Proveer instrucciones claras al usuario sobre qué variables de entorno o certificados necesita para que el comando tenga éxito.
- Sugerir flujos de CI/CD (ej. GitHub Actions) si el usuario lo requiere.

## Ejemplo de uso interno

- **Entrada:** "Generar APK para producción"
- **Acción:** Verificar dependencias, asegurar configuración de ProGuard/R8, y proporcionar el comando `flutter build apk --release --obfuscate --split-debug-info=./debug_info`.
