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

## Localización de la interfaz
- Idiomas soportados: español (`es`) e inglés (`en`).
- La selección inicial sigue automáticamente el `Locale` informado por navegador, Android o iOS.
- Cualquier variante regional española (`es-ES`, `es-MX`, etc.) usa español.
- Inglés es el idioma de respaldo para locales no soportados.
- La localización pertenece a `app/presentation` y no cambia contratos de dominio, BLoC, motores ni FFI.
- Textos visibles, ayudas, semántica accesible y errores conocidos deben resolverse en el idioma activo.
