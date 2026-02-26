# T032 - Adaptador OpenAI para song tuning optimizado

## Estado
- todo

## Prioridad
- P0

## Epic
- E06

## Dependencias
- T031

## Objetivo
Implementar en `data` un adaptador OpenAI que reciba nombre de cancion y devuelva afinacion de guitarra con estrategia de minimo consumo de tokens.

## Entradas
- `specs/epics/E06-song-tuning-openai.md`
- `lib/data/README.md`
- Contratos de dominio creados en T031

## Alcance
- Implementar cliente de infraestructura para invocar API OpenAI.
- Usar prompt compacto y salida JSON estricta para minimizar tokens.
- Definir configuracion de `model`, `temperature`, `max_output_tokens` y timeout.
- Mapear respuesta API al contrato de dominio.
- Mapear errores tecnicos (network, auth, rate limit, schema invalido) a errores de dominio.

## Fuera de alcance
- Construccion de UI.
- Persistencia de historico de consultas.

## Entregables
- Implementacion `data` del servicio de song tuning basado en OpenAI.
- Configuracion para inyectar API key por entorno (sin hardcode).
- Tests unitarios de parseo/mapeo y errores principales.

## Criterios de aceptacion
- La solicitud enviada a OpenAI incluye solo contexto minimo necesario.
- La respuesta se valida contra un esquema esperado antes de mapear a dominio.
- El servicio retorna resultado estable ante casos: exito, no encontrado, timeout, respuesta invalida.
- No se exponen secretos en logs ni en codigo fuente.

## Riesgos
- Variabilidad de respuestas en canciones poco conocidas.
- Cambios de API/modelo que obliguen ajuste de payload.

## Plan de implementacion
1. Crear payload minimo y contrato de respuesta estructurada.
2. Implementar adaptador HTTP + mapeo a dominio.
3. Cubrir parser y errores con tests unitarios.
4. Verificar que configuracion de token budget quede centralizada.

## Evidencia de cierre
- Pendiente.

