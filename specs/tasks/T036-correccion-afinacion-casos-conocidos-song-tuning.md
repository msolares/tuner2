# T036 - Correccion de afinacion en casos conocidos de song tuning

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E06

## Dependencias
- T032

## Objetivo
Aplicar una correccion deterministica en el adaptador de song tuning para canciones con afinacion de referencia conocida, evitando falsos positivos en afinacion estandar.

## Entradas
- `lib/data/song_tuning/openai_song_tuning_service.dart`
- `test/data/song_tuning/openai_song_tuning_service_test.dart`

## Alcance
- Agregar capa de normalizacion/correccion de resultado posterior al parseo.
- Incluir caso validado: `November Rain` -> `Eb Standard`.
- Mantener trazabilidad: conservar afinacion sugerida por modelo como alternativa cuando difiera.
- Cubrir comportamiento con tests unitarios.

## Fuera de alcance
- Cambios de UI.
- Base extensa de afinaciones por cancion.

## Entregables
- Servicio con post-procesado deterministico para casos conocidos.
- Tests en verde para override y no-regresion.

## Criterios de aceptacion
- Consulta de `November Rain` retorna afinacion principal `Eb Standard`.
- El flujo sigue siendo robusto ante respuestas validas/invalidas del proveedor.
- `flutter test` verde en modulos impactados.

## Riesgos
- Sobreajuste si se amplian overrides sin validacion.

## Plan de implementacion
1. Implementar estrategia de override por `songName` normalizado.
2. Preservar respuesta del modelo como alternativa cuando aplique.
3. Agregar tests de precision y regresion.

## Evidencia de cierre
- Pendiente.
