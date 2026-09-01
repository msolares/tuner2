# T058 - Casos de uso y maquina de sesion educativa

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057

## Objetivo
Implementar UC-L00..UC-L10 y una maquina de estados determinista, pura y comprobable con repositorio/clock/analyzer fake.

## Entradas
- `specs/learning/use-cases.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Carga/preparacion/inicio/parada.
- Listado ordenado del catalogo y sus errores.
- Tick musical y bloqueo por target.
- Evaluacion de nota y acorde.
- Pausa, velocidad, repetir seccion y reentrada.
- `LessonViewportSlice` acotado y libre de conceptos de UI.
- Errores y transiciones invalidas.

## Fuera de alcance
- Adaptadores reales, BLoC, Flutter y XML.

## Criterios de aceptación
- Matriz de estados cubierta con tests unitarios.
- UC-L00 valida catalogos vacios, duplicados, desordenados y fallos sin filtrar detalles de data.
- Observaciones antiguas o ataques consumidos no desbloquean.
- Dos notas iguales exigen ataques distintos; ties no.
- Reentrada conserva resultado y no reevalua el target acertado.
- Tests usan tiempo virtual y no contienen esperas reales.

## Evidencia de cierre
- Pendiente.
