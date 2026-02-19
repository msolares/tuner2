# T013 - Politica de errores

## Estado
- done

## Prioridad
- P0

## Epic
- E05

## Dependencias
- T005, T009

## Objetivo
Catalogar errores por capa y estrategia de recuperacion.

## Entregables
- Tabla de errores y UX esperada.

## Criterios de aceptacion
- Permisos, audio y engine cubiertos.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Catalogo de errores por capa y estrategia de recuperacion:
- `lib/presentation/bloc/tuner_error_policy.dart`
- Tabla de errores y UX esperada:
- `lib/presentation/bloc/ERROR_POLICY.md`
- Aplicacion de politica en flujo BLoC:
- `lib/presentation/bloc/tuner_bloc.dart`
- Presentacion de mensaje de error en UI:
- `lib/presentation/screens/tuner_screen.dart`
- Cobertura explicita:
- Permisos (`audio_permission_denied`)
- Audio/stream (`audio_device_unavailable`, `engine_stream_error`)
- Engine/FFI (`engine_start_failed`, `ffi_*`, `unexpected_error`)

