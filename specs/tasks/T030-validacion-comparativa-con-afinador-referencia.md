# T030 - Validacion comparativa con afinador de referencia

## Estado
- todo

## Prioridad
- P0

## Epic
- E05

## Dependencias
- T028, T029, T026

## Objetivo
Validar en entorno real que la lectura de nota/cents del afinador sea confiable frente a una referencia externa y bajo escenarios de producto obligatorios.

## Entradas
- `specs/quality/pitch-accuracy-protocol.md`
- `specs/quality/dart-test-plan.md`
- `specs/quality/rust-test-plan.md`
- `specs/quality/ffi-integration-test-plan.md`
- `specs/quality/web-compat-matrix.md`

## Alcance
- Ejecutar protocolo de precision por plataforma (Android, iOS, Web).
- Comparar salida de la app contra referencia (afinador externo o generador de tonos calibrado).
- Registrar metricas de error absoluto en cents y estabilidad temporal.
- Documentar hallazgos, desvios y acciones de correccion.

## Fuera de alcance
- Rediseno de producto/UI.
- Cambio de contratos de dominio/FFI.

## Entregables
- Reporte de resultados por plataforma con metricas comparables.
- Evidencia enlazada (logs, capturas/video, notas tecnicas).
- Recomendacion final de estado tecnico (Go/No-Go).

## Criterios de aceptacion
- Error absoluto mediano <= +/- 5 cents en notas sostenidas.
- Percentil 95 de error absoluto <= +/- 15 cents en escenario controlado.
- Escenarios obligatorios cubiertos: nota sostenida, cambios rapidos, ruido, A4 en caliente, permisos denegados.
- Evidencia integrada en esta task y referenciada desde T026.

## Riesgos
- Variabilidad por hardware/microfono entre dispositivos.
- Diferencias de latencia entre navegadores en Web.

## Plan de implementacion
1. Ejecutar protocolo estandarizado de precision.
2. Capturar datos por plataforma y calcular metricas.
3. Comparar contra umbrales objetivos.
4. Registrar incidencias y proponer acciones.
5. Consolidar conclusion Go/No-Go con evidencia.

## Evidencia de cierre
- Pendiente.
