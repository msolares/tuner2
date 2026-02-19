# T010 - Pantalla MVP afinador

## Estado
- done

## Prioridad
- P0

## Epic
- E04

## Dependencias
- T009

## Objetivo
Definir UI minima del afinador con feedback en tiempo real.

## Entregables
- Especificacion de componentes y comportamiento visual.

## Criterios de aceptacion
- Indicadores de nota, cents y in-tune definidos.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Pantalla MVP implementada en:
- `lib/presentation/screens/tuner_screen.dart`
- App shell conectada al BLoC en:
- `lib/main.dart`
- Especificacion de componentes y comportamiento visual en:
- `lib/presentation/screens/README.md`
- Indicadores definidos:
- Nota detectada, frecuencia en Hz, desviacion en cents e indicador `in tune/out of tune`.
- Flujo UI minimo:
- Permiso (demo) -> Start -> feedback en tiempo real -> Stop.

