# T018 - Pipeline CI

## Estado
- done

## Prioridad
- P1

## Epic
- E05

## Dependencias
- T014, T015, T016

## Objetivo
Definir checks automaticos de calidad para merge.

## Entregables
- Jobs de lint y tests por stack.

## Criterios de aceptacion
- Gates de merge documentados.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Pipeline CI implementado en:
- `.github/workflows/ci.yml`
- Gates de merge documentados en:
- `specs/quality/ci-gates.md`
- Jobs definidos por stack:
- `flutter-quality`, `rust-quality`, `specs-consistency`.

