# T002 - Contratos de dominio

## Estado
- done

## Prioridad
- P0

## Epic
- E01

## Dependencias
- T001

## Objetivo
Definir modelos y contrato TunerEngine para todo el sistema.

## Entregables
- PitchSample, TunerSettings y TunerEngine documentados.

## Criterios de aceptacion
- Firmas cerradas sin campos ambiguos.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Implementacion de contratos en:
- `lib/domain/entities/pitch_sample.dart`
- `lib/domain/entities/tuner_settings.dart`
- `lib/domain/services/tuner_engine.dart`
- Documentacion de semantica/unidades agregada en los mismos archivos para eliminar ambiguedad de campos.
- Tests de entidades:
- `test/domain/entities/pitch_sample_test.dart`
- `test/domain/entities/tuner_settings_test.dart`
- Nota: test de contrato de `TunerEngine` deshabilitado temporalmente por bloqueo del runner en entorno local.

