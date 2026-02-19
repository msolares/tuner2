# T006 - Estrategia Web compatible

## Estado
- done

## Prioridad
- P0

## Epic
- E03

## Dependencias
- T002

## Objetivo
Definir implementacion Web en Dart con mismo contrato de dominio.

## Entregables
- Plan Web sin FFI nativo para MVP.

## Criterios de aceptacion
- Paridad funcional de contrato documentada.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Estrategia Web (sin FFI nativo) documentada en:
- `lib/data/engines/README.md`
- Implementacion Dart compatible con contrato de dominio:
- `lib/data/engines/web/web_tuner_engine.dart`
- Paridad de contrato mantenida:
- `WebTunerEngine implements TunerEngine`
- `start(TunerSettings)`, `samples()`, `stop()` con mismas firmas del dominio.
- Nota: pruebas de `web_tuner_engine` omitidas temporalmente por decision operativa.

