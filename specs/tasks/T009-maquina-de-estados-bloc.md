# T009 - Maquina de estados BLoC

## Estado
- done

## Prioridad
- P0

## Epic
- E01

## Dependencias
- T002, T003

## Objetivo
Definir eventos, estados y transiciones de tuner_bloc.

## Entregables
- Matriz evento->estado con errores y recuperacion.

## Criterios de aceptacion
- Sin transiciones invalidas pendientes.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Contrato de eventos implementado en:
- `lib/presentation/bloc/tuner_event.dart`
- Contrato de estados implementado en:
- `lib/presentation/bloc/tuner_state.dart`
- Maquina de estados y transiciones implementada en:
- `lib/presentation/bloc/tuner_bloc.dart`
- Matriz evento -> estado (incluye errores y recuperacion) documentada en:
- `lib/presentation/bloc/README.md`

