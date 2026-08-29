# T047 - Integración cross-platform y lifecycle del metrónomo

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E07, E05

## Dependencias
- T042, T043, T044, T045, T046

## Objetivo
Integrar los engines por plataforma con el composition root y verificar exclusión mutua, audio focus y limpieza de recursos.

## Entradas
- Entregables T042 a T046.
- `lib/app/platform_dependencies*.dart`
- Planes oficiales de calidad en `specs/quality/`.

## Alcance
- Registrar el engine correcto por plataforma.
- Validar start/stop y update desde UI hasta audio.
- Probar cambios de pestaña, background/foreground y errores de audio.
- Verificar que afinador y metrónomo nunca quedan activos simultáneamente.
- Confirmar que el afinador no sufre regresiones funcionales ni visuales.

## Fuera de alcance
- Nuevas funciones musicales.

## Entregables
- Integración completa, tests E2E y correcciones dentro del alcance.

## Criterios de aceptación
- Flujo completo funcional en Android, iOS y Web.
- No existen handles, streams, timers o contextos de audio huérfanos.
- Errores de inicialización/parada se presentan y permiten recuperación.
- Suites actuales del afinador y nuevas del metrónomo quedan en verde.

## Riesgos
- Diferencias de audio focus y políticas de autoplay entre plataformas.

## Evidencia de cierre
- Composition root y dependencias de plataforma conectados.
- Regresión de lifecycle corregida: `inactive` ya no detiene el afinador; solo se liberan audio y streams en `paused`, `hidden` o `detached`.
- El cambio de preset reinicia el motor y vuelve a suscribir `samples()`, evitando que Guitarra o el regreso a Cromático queden conectados a un stream anterior.
- Pruebas automatizadas para lifecycle transitorio y secuencia Cromático -> Guitarra -> Cromático.
- Android: build debug correcto.
- Web: build correcto.
- Tests de integración del shell y lifecycle automatizado en verde.
- Suite completa Flutter: 86 tests en verde y 1 test histórico marcado explícitamente como skip.
- Pendiente para cierre: validación física iOS y evidencia de audio focus por plataforma.
