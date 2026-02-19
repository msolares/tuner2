# T012 - Presets de instrumento

## Estado
- done

## Prioridad
- P1

## Epic
- E04

## Dependencias
- T011

## Objetivo
Definir presets iniciales y comportamiento asociado.

## Entregables
- Lista de presets MVP y reglas de uso.

## Criterios de aceptacion
- Preset activo altera parametros segun contrato.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Lista de presets MVP definida en:
- `lib/domain/entities/instrument_preset_profile.dart`
- Catalogo de presets implementado en:
- `lib/domain/services/instrument_preset_catalog.dart`
- `lib/data/settings/default_instrument_preset_catalog.dart`
- `lib/data/settings/PRESETS.md`
- Comportamiento aplicado en BLoC:
- `lib/presentation/bloc/tuner_bloc.dart` (`SelectPreset` actualiza `instrumentPreset`, `noiseGateDb`, `smoothing`).
- Integracion en UI:
- `lib/presentation/screens/tuner_screen.dart` (selector de preset + visualizacion de parametros).
- Integracion en app:
- `lib/main.dart` (inyeccion de `DefaultInstrumentPresetCatalog`).

