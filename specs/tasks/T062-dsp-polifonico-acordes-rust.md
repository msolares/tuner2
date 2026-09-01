# T062 - DSP polifonico de acordes en Rust

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057, T038, T040

## Objetivo
Implementar en Rust evidencia cromatica y deteccion de ataque dirigida a acordes, sin alterar el comportamiento ni ABI del afinador existente.

## Entradas
- `specs/epics/E08-aprendizaje-guitarra-musicxml.md`
- `specs/quality/learning-mode-test-plan.md`
- `rust/engine/`

## Alcance
- Front-end espectral polifonico modular.
- Doce intensidades normalizadas C..B.
- `onsetSequence` y confidence.
- Ventana de rasgueo y control de armonicos.
- Tests sintéticos y corpus PCM inicial.
- Presupuesto de memoria/CPU y manejo de NaN/error.

## Fuera de alcance
- FFI, Dart, clasificacion libre de acordes o scoring.

## Criterios de aceptación
- API Rust interna separada del detector monofónico.
- Afinador mantiene resultados y tests previos.
- Gates de precision/latencia del corpus oficial cumplidos o evidencia que bloquea el cierre.
- Sin panic, buffers crecientes o allocation no acotada.

## Evidencia de cierre
- Pendiente.
