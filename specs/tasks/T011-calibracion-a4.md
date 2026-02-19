# T011 - Calibracion A4

## Estado
- done

## Prioridad
- P0

## Epic
- E04

## Dependencias
- T002, T009

## Objetivo
Definir rango, default y persistencia de A4.

## Entregables
- Reglas de validacion y efecto en calculo de nota.

## Criterios de aceptacion
- Cambio de A4 impacta engine en caliente.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Reglas de validacion A4 definidas en dominio:
- `lib/domain/entities/tuner_settings.dart`
- Persistencia A4 implementada en data:
- `lib/domain/services/a4_calibration_store.dart`
- `lib/data/settings/shared_preferences_a4_calibration_store.dart`
- `lib/data/settings/README.md`
- Efecto en caliente sobre engine aplicado en BLoC:
- `lib/presentation/bloc/tuner_bloc.dart` (evento `UpdateA4` con restart cuando esta escuchando).
- UI de calibracion A4 implementada en:
- `lib/presentation/screens/tuner_screen.dart`
- Integracion de store en app shell:
- `lib/main.dart`

