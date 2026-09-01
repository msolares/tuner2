# Handoffs de desarrollo

## Proposito

Permitir que otra ventana de contexto continue el desarrollo con la frase `sigue con el desarrollo`, sin depender del historial de chat.

## Fuente operativa

`current.md` contiene el ultimo estado conocido. Su informacion es orientativa y nunca prevalece sobre:

1. `AGENTS.md` y Clean Architecture.
2. Epic y contratos de feature.
3. Task numerada y sus dependencias.
4. Estado real de Git, codigo y tests.

## Actualizacion obligatoria

Actualizar `current.md`:

- al cerrar una task;
- antes de cambiar de ventana o pausar un bloque;
- si cambia la siguiente task, un gate o una deuda relevante.

Debe incluir rama, ultima task, estado del worktree esperado, entregables, gates, siguiente task, orden de lectura, skills y limites de alcance. No copiar specs completas ni usar el handoff para declarar una task `done`.
