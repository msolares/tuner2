# E01 - Flutter Shell

## Objetivo
Definir la app shell en Flutter con separación por capas y estado basado en BLoC.

## Arquitectura de capas
- `presentation`: widgets, pantallas, BLoC, mapeo de estado a UI.
- `domain`: entidades, contratos de repositorio/servicios, casos de uso.
- `data`: implementación de acceso a audio, engine y adaptadores.

## Reglas de dependencia
- `presentation -> domain` permitido.
- `domain -> data` no permitido.
- `data -> domain` permitido solo para implementar contratos.

## Contratos públicos (Dart)
- `PitchSample { hz, note, cents, confidence, timestampMs }`
- `TunerSettings { a4Hz, instrumentPreset, noiseGateDb, smoothing }`
- `abstract class TunerEngine { start, samples, stop }`

## Criterios de aceptación
- Eventos y estados de BLoC definidos.
- Manejo de permisos de audio cubierto por flujo.
- Estrategia Web compatible con el mismo contrato de dominio.
