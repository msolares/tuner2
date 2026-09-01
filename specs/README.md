# Specs del Proyecto Afinador

Este directorio es la fuente de verdad para alcance, arquitectura y ejecución.

## Estado actual
- Arquitectura objetivo: Flutter + Rust FFI.
- MVP: afinación en tiempo real + calibración A4.
- Expansión planificada: metrónomo configurable como segundo modo (`E07`).
- Nueva expansión aprobada: aprendizaje de guitarra MusicXML con notas/acordes y mástil Flutter (`E08`).
- Fase posterior cerrada: audio real, beat map y time-stretch (`E09`).
- Plataformas objetivo: Android, iOS y Web.
- Idioma oficial de documentación: español.

## Estructura
- `specs/epics/`: decisiones de arquitectura, diseño y alcance por bloque.
- `specs/tasks/`: backlog ejecutable con IDs, dependencias y criterios de aceptación.
- `specs/architecture/`: contratos transversales de capas y dependencias.
- `specs/learning/`: contratos educativos, casos de uso y perfil MusicXML.
- `specs/design/`: especificaciones visuales y referencias aprobadas.
- `specs/quality/`: planes de prueba y gates.

## Convenciones
- IDs de epic: `E00`, `E01`, ...
- IDs de tasks: `T001`, `T002`, ...
- Estados: `todo`, `in_progress`, `blocked`, `done`.
- Prioridad: `P0`, `P1`, `P2`.

## Flujo de trabajo
1. Leer el epic asociado.
2. Ejecutar una task completa por vez.
3. Cumplir Definition of Done de `specs/tasks/README.md`.
4. Registrar evidencia mínima en la misma task.

## Inicio del modo educativo

Orden de lectura obligatorio:

1. `AGENTS.md`.
2. `specs/architecture/clean-architecture.md`.
3. `specs/epics/E08-aprendizaje-guitarra-musicxml.md`.
4. Specs educativas enlazadas.
5. Task concreta T057..T072 o T077.

E09 y T073..T076 no comienzan hasta cerrar T072.
