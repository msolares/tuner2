# T041 - Contratos de dominio del metrónomo

## Estado
- done

## Prioridad
- P0

## Epic
- E07

## Dependencias
- T020

## Objetivo
Cerrar las entidades, invariantes y contratos públicos del metrónomo sin modificar los contratos del afinador.

## Entradas
- `specs/epics/E07-metronomo.md`
- `lib/domain/`
- `AGENTS.md`

## Alcance
- Implementar `TimeSignature`, `BeatConfig`, `MetronomeSettings` y `MetronomeTick`.
- Implementar enums de acento y subdivisión.
- Definir `MetronomeEngine` y `MetronomeSettingsStore`.
- Definir normalización al cambiar de numerador.
- Agregar catálogo de compases predefinidos en dominio.
- Documentar unidades, rangos, errores e invariantes.

## Fuera de alcance
- Audio, FFI, persistencia concreta, BLoC o UI.

## Entregables
- Contratos Dart inmutables y tests unitarios.
- Actualización de contratos globales en `AGENTS.md` al implementar.

## Criterios de aceptación
- No es posible construir una configuración inválida.
- Existe exactamente una tónica por configuración.
- Los cambios de compás conservan de forma determinista los tiempos compatibles.
- Los tests cubren límites, igualdad, copia y normalización.
- No cambia ninguna firma del dominio del afinador.

## Riesgos
- Modelar figuras absolutas generaría configuraciones inválidas para denominadores diferentes.

## Evidencia de cierre
- Implementados contratos e invariantes en `lib/domain/entities/time_signature.dart`, `metronome_settings.dart` y `metronome_tick.dart`.
- Implementados `MetronomeEngine`, `MetronomeSettingsStore` y catálogo de compases.
- Agregada serialización versionada y normalización determinista al cambiar de compás.
- `test/domain/entities/metronome_settings_test.dart`: 8 tests en verde.
- `dart analyze`: sin errores ni warnings del cambio.
