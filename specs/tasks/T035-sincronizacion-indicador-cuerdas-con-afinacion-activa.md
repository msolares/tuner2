# T035 - Sincronizacion del indicador de cuerdas con afinacion activa

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E06

## Dependencias
- T012, T033

## Objetivo
Hacer que las letras de cuerdas en la parte superior reflejen la afinacion activa cuando se cambia el preset desde el desplegable o cuando se obtiene una afinacion por cancion.

## Entradas
- `lib/presentation/screens/tuner_screen.dart`
- `lib/presentation/bloc/song_tuning_bloc.dart`
- `lib/presentation/bloc/song_tuning_event.dart`
- `test/presentation/bloc/song_tuning_bloc_test.dart`

## Alcance
- Reemplazar el listado fijo de cuerdas por un mapeo dinamico por preset.
- Aplicar como fuente temporal la afinacion primaria encontrada por song tuning cuando la consulta sea exitosa.
- Al cambiar preset manualmente, desactivar la afinacion encontrada para volver a mostrar el preset elegido.
- Agregar pruebas de mapeo y de evento de limpieza de resultado.

## Fuera de alcance
- Cambios de contrato en `TunerEngine` o FFI.
- Aplicar automaticamente la afinacion encontrada al motor de deteccion.

## Entregables
- Indicador superior sincronizado con afinacion activa.
- Evento en `SongTuningBloc` para limpiar resultado aplicado al encabezado.
- Tests unitarios en verde para los nuevos casos.

## Criterios de aceptacion
- Al cambiar preset desde UI, el indicador superior muestra sus cuerdas esperadas.
- Al obtener una cancion con exito, el indicador superior muestra la afinacion encontrada.
- No hay crash al alternar repetidamente entre preset y consulta de cancion.
- `flutter test` verde en modulos impactados.

## Riesgos
- Orden de cuerdas invertido (grave/aguda) en representacion visual.

## Plan de implementacion
1. Extraer y testear funciones de mapeo de cuerdas para preset y song tuning.
2. Integrar mapeo en `_StringSelector` y flujo de `TunerScreen`.
3. Agregar evento para limpiar resultado de song tuning al cambiar preset.
4. Ejecutar tests y registrar evidencia.

## Evidencia de cierre
- Pendiente.
