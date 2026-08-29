# T043 - Engine Web del metrónomo

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E07

## Dependencias
- T041

## Objetivo
Implementar en Dart Web el mismo contrato `MetronomeEngine` mediante scheduler monotónico y backend de audio Web.

## Entradas
- `specs/epics/E07-metronomo.md`
- `lib/data/engines/web/`
- `lib/app/platform_dependencies_web.dart`

## Alcance
- Preparar el backend de audio tras gesto del usuario.
- Programar clic fuerte, normal y subdivisiones desde objetivos absolutos.
- Aplicar actualizaciones en el siguiente límite de compás.
- Emitir ticks visuales sincronizados con el audio programado.
- Liberar nodos, timers auxiliares y streams en stop/dispose.

## Fuera de alcance
- Rust, BLoC o UI.

## Entregables
- Adaptador Web y suite de conformidad compartida con móvil.

## Criterios de aceptación
- Implementa exactamente el contrato de T041.
- No usa `Timer.periodic` ni repaints de UI como fuente de verdad temporal.
- Recupera correctamente contextos suspendidos por políticas del navegador.
- Cumple los presupuestos de jitter y deriva de E07 en navegadores soportados.
- Tests Web en verde.

## Riesgos
- Throttling y suspensión del navegador al perder visibilidad.

## Evidencia de cierre
- Sink Web con WAV `data:` URI y pool de reproductores implementado.
- Suite compartida del scheduler en verde.
- `flutter build web --no-pub`: correcto.
- El build JavaScript está soportado; el plugin informa incompatibilidad futura con Wasm.
- Pendiente antes de marcar `done`: medición de jitter/deriva en navegador real.
