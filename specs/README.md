# Specs del Proyecto Afinador

Este directorio es la fuente de verdad para alcance, arquitectura y ejecución.

## Estado actual
- Arquitectura objetivo: Flutter + Rust FFI.
- MVP: afinación en tiempo real + calibración A4.
- Plataformas objetivo: Android, iOS y Web.
- Idioma oficial de documentación: español.

## Estructura
- `specs/epics/`: decisiones de arquitectura, diseño y alcance por bloque.
- `specs/tasks/`: backlog ejecutable con IDs, dependencias y criterios de aceptación.

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
