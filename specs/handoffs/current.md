# Handoff actual

## Punto de reanudacion

- Rama: `aprendizaje-musical`.
- Ultimo bloque cerrado: T057 - Contratos de dominio del modo educativo.
- Estado oficial T057: `done` con evidencia en su task.
- Siguiente task: T058 - Casos de uso y maquina de sesion educativa.
- Estado esperado del worktree al reanudar: limpio tras confirmar el commit del bloque; comprobar siempre con `git status --short`.

## Realizado

- Creado `lib/domain/learning/` sin dependencias de Flutter/plataforma.
- Implementados chart, tuning, notas, acordes soportados, contenido, targets/observaciones, politica, clock tick, estados/proyeccion, errores y puertos.
- Cerradas reglas de construccion, rechazo, igualdad, copia e inmutabilidad en `specs/learning/domain-contracts.md`.
- Añadidas 29 pruebas específicas y un test de imports prohibidos.

## Evidencia vigente

- `flutter test test/domain/learning`: 29 passed.
- `flutter test`: 131 passed, 1 skip preexistente.
- `flutter analyze --no-fatal-infos`: exit 0; 29 infos preexistentes, ninguno introducido por T057.
- `git diff --check`: limpio.
- No se toco Rust/FFI, data, presentation ni app.

## Como continuar

1. Leer `AGENTS.md` y este handoff.
2. Aplicar, en orden, `$project-clean-architecture`, `$spec-task-executor` y `$guitar-learning-mode`.
3. Leer completos `specs/tasks/T058-casos-uso-y-sesion-educativa.md`, E08, `domain-contracts.md` y `use-cases.md`.
4. Confirmar que T057 sigue `done` y que Git no contiene cambios ajenos.
5. Declarar el mapa de archivos por capa y marcar T058 `in_progress`.
6. Implementar solo casos de uso y maquina de sesion pura con fakes; registrar evidencia y actualizar este handoff al cerrar.

## Limites del siguiente bloque

- T058 no implementa MusicXML, data adapters, DSP/FFI, BLoC, UI ni reloj real.
- No cambiar `TunerEngine` ni `MetronomeEngine`.
- No iniciar E09 ni tareas dependientes antes de cerrar sus prerequisitos.
- Ante discrepancia, corregir primero la fuente contractual superior; no decidir desde el BLoC.
