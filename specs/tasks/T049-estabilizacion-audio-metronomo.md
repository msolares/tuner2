# T049 - Estabilización de audio del metrónomo

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E07, E05

## Dependencias
- T042, T043

## Objetivo
Eliminar los bloqueos y silencios progresivos del metrónomo bajo subdivisiones rápidas sin cambiar los contratos de dominio ni la UI.

## Entradas
- `lib/data/metronome/`
- `test/data/metronome/`
- `specs/epics/E07-metronomo.md`

## Alcance
- Precargar una vez los clics fuerte y normal en pools independientes de baja latencia.
- Impedir que cada pulso vuelva a preparar la fuente de audio.
- Acotar y observar las operaciones de reproducción en vuelo.
- Evitar ráfagas de clics vencidos tras pausas del isolate.
- Hacer `start`, `stop` y cleanup recuperables ante operaciones lentas o fallidas.
- Añadir pruebas de estrés para semicorcheas a 300 BPM, errores y lifecycle repetido.

## Fuera de alcance
- Cambios de UI, dominio musical, persistencia o afinador.
- Ejecución en segundo plano.
- Sustitución completa por un renderizador PCM nativo antes de medir esta corrección.

## Criterios de aceptación
- No se crea ni prepara una fuente por pulso.
- El número de reproducciones simultáneas queda acotado y no crece con el tiempo.
- Un backend lento no provoca backlog ni una ráfaga posterior.
- Los fallos asíncronos llegan al stream del engine y permiten recuperación.
- `flutter analyze`, `flutter test`, build Android y build Web quedan en verde.

## Evidencia de cierre
- Pendiente.
