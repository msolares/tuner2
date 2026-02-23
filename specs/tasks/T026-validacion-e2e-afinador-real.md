# T026 - Validacion E2E de afinador real

## Estado
- todo

## Prioridad
- P0

## Epic
- E05

## Dependencias
- T022, T023, T024, T025, T028, T029, T030

## Objetivo
Ejecutar validacion integral del afinador con microfono real en Android, iOS y Web usando los planes de calidad oficiales.

## Entregables
- Evidencia de pruebas funcionales por plataforma.
- Registro de excepciones, fallas y acciones de correccion.
- Resultado final Go/No-Go para MVP.
- Consolidado de metricas de precision segun `specs/quality/pitch-accuracy-protocol.md`.

## Criterios de aceptacion
- Se validan escenarios obligatorios: nota sostenida, cambios rapidos, ruido, cambio A4 en caliente y permisos denegados.
- No hay crashes en `start/stop` repetido ni leaks detectables de recursos.
- Pruebas definidas en `specs/quality/*.md` ejecutadas con evidencia enlazada.
- Protocolo de precision `specs/quality/pitch-accuracy-protocol.md` ejecutado en Android, iOS y Web.
- Error absoluto mediano <= +/- 5 cents y p95 <= +/- 15 cents en escenario controlado.
- Estado de release documentado segun `specs/quality/release-checklist-mvp.md`.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Diferencias de comportamiento por hardware real no cubiertas por emuladores.

## Evidencia de cierre
- Pendiente.
