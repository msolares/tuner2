# T048 - Validación de calidad y release del metrónomo

## Estado
- todo

## Prioridad
- P0

## Epic
- E07, E05

## Dependencias
- T047, T049

## Objetivo
Cerrar el metrónomo con evidencia reproducible de precisión temporal, compatibilidad, accesibilidad y ausencia de regresiones.

## Entradas
- `specs/quality/`
- Implementación integrada de T047.

## Alcance
- Crear `specs/quality/metronome-test-plan.md`.
- Crear matriz de compases, BPM, subdivisiones y plataformas.
- Medir jitter y deriva en escenarios definidos por E07.
- Ejecutar pruebas prolongadas, start/stop repetido y cambios en caliente.
- Validar accesibilidad y tamaños responsive.
- Actualizar gates CI y checklist release si procede.

## Fuera de alcance
- Ajustes funcionales no necesarios para cumplir E07.

## Entregables
- Plan, matriz y evidencias por Android, iOS y Web.
- Checklist Go/No-Go actualizado.

## Criterios de aceptación
- Se cumplen los presupuestos temporales del epic con evidencia enlazada.
- Todos los presets, compases personalizados límite y subdivisiones están cubiertos.
- `flutter analyze`, `flutter test`, pruebas Web y `cargo test` en verde.
- No quedan decisiones abiertas ni regresiones conocidas P0/P1.

## Riesgos
- Las métricas pueden variar según carga o dispositivo y requieren protocolo de medición estable.

## Evidencia de cierre
- Pendiente.
