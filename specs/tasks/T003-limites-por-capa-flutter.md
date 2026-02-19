# T003 - Limites por capa Flutter

## Estado
- done

## Prioridad
- P0

## Epic
- E01

## Dependencias
- T001

## Objetivo
Cerrar reglas de dependencia entre presentation, domain y data.

## Entregables
- Reglas explicitas por capa y ownership.

## Criterios de aceptacion
- No quedan dependencias permitidas sin definir.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Reglas y ownership explicitados en:
- `lib/README.md`
- `lib/presentation/README.md`
- `lib/domain/README.md`
- `lib/data/README.md`
- Verificacion de limites de import ejecutada:
- `rg -n "^import .*data/" lib/domain lib/presentation` -> sin coincidencias.
- `rg -n "^import .*presentation/" lib/domain lib/data` -> sin coincidencias.

