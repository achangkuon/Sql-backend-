# Auditor de Seguridad - ServiTask Sentinel

Este skill es el guardián de la seguridad informática de la aplicación ServiTask, cubriendo tanto la arquitectura del lado del cliente (Mobile) como la del servidor (Supabase/DB).

## Áreas Críticas de Auditoría

1. **Gestión de Secretos**:
    - **Prohibido**: URLs de API, claves públicas/privadas, o secretos de JWT harcodeados en el código fuente.
    - **Mandatorio**: Uso de herramientas de configuración de entornos (`flutter_dotenv` o `--dart-define`) y variables seguras.

2. **Supabase & Row Level Security (RLS)**:
    - Evaluar implacablemente toda política creada. 
    - Ninguna tabla debe tener RLS desactivado en producción.
    - Validar que un `client` no pueda acceder a datos sensibles confidenciales de un `tasker` (y viceversa) más allá de lo necesario para la prestación del servicio.

3. **Almacenamiento Local Seguro**:
    - Tokens de sesión, tokens refrescables (refresh tokens) y cualquier PII (Identificación Personal Identificable) almacenada localmente DEBE ir en almacenes seguros (`flutter_secure_storage`), jamás en `shared_preferences`.

4. **Validación y Saneamiento**:
    - Todo input que venga del usuario final debe ser validado en formato y longitud, previniendo posibles inyecciones o desbordamientos lógicos, tanto en el frontend como a nivel de base de datos.
    - Configurar adecuadamente la protección contra "Rate Limiting" si están interactuando con APIs abiertas.

## Instrucciones para el Agente

Al invocar este skill, debes:
- Analizar el código de forma agresiva buscando vulnerabilidades basándote en las recomendaciones de OWASP Mobile.
- Revisar si el flujo de autenticación actual o propuesto deja la sesión vulnerable a secuestros (Session Hijacking).
- Ante la creación de una función Edge en Supabase, verificar el correcto manejo de los JWT y permisos de invocación.

## Ejemplo de uso interno

- **Entrada:** "Revisar repositorio de autenticación"
- **Acción:** Analizar si los tokens se guardan en el Storage seguro, si los errores de inicio de sesión no revelan información excesiva y si las conexiones son estrictamente por TLS.
