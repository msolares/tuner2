# T063 - ABI FFI del PerformanceAnalyzer

## Estado
- todo

## Prioridad
- P0

## Epic
- E08, E03

## Dependencias
- T057, T062

## Objetivo
Definir e implementar un ABI independiente para observaciones educativas monofonicas/polifonicas sin cambiar `tuner_*`.

## Entradas
- `rust/engine/FFI_CONTRACT.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Funciones `performance_init`, `performance_set_target`, `performance_process_frame`, `performance_dispose`.
- Structs C ABI versionados con tamaños/tipos fijos.
- Resultado discriminado nota/acorde, 12 strengths, onset y errores.
- Validacion de punteros, longitudes, sample rate y lifecycle.
- Documentacion y tests de integracion ABI.

## Fuera de alcance
- Captura de microfono, BLoC o UI.

## Criterios de aceptación
- `tuner_*` permanece binariamente igual.
- Layout ABI documentado y comprobado.
- Handle invalido y frames corruptos no causan crash.
- Start/setTarget/process/dispose repetido queda cubierto.

## Evidencia de cierre
- Pendiente.
