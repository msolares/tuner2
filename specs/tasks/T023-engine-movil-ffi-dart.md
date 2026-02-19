# T023 - Engine movil FFI en Dart

## Estado
- todo

## Prioridad
- P0

## Epic
- E03

## Dependencias
- T005, T008, T022

## Objetivo
Implementar `TunerEngine` movil real en Dart usando FFI hacia el contrato Rust definido.

## Entregables
- Implementacion `MobileFfiTunerEngine` en `lib/data/engines/`.
- Binding Dart FFI para `tuner_init`, `tuner_process_frame`, `tuner_update_config`, `tuner_dispose`.
- Mapeo de errores FFI a codigos de error del BLoC.

## Criterios de aceptacion
- El engine inicializa y libera handles sin leaks en ciclos repetidos.
- Cada frame PCM se procesa por FFI y se convierte a `PitchSample`.
- `UpdateA4`/preset actualiza configuracion en caliente mediante `tuner_update_config`.
- Errores FFI (`invalid_handle`, `invalid_frame`, `invalid_sample_rate`, internos) se propagan al BLoC.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Mapeo incorrecto de tipos entre Dart y Rust que degrade precision o estabilidad.

## Evidencia de cierre
- Pendiente.
