# Plan de pruebas Rust (T015)

## Objetivo

Validar exactitud, robustez y seguridad basica del engine Rust.

## Metricas minimas

- Precision objetivo en senal limpia sostenida:
- error mediano <= +/- 5 cents en rango 82 Hz a 880 Hz.
- Latencia objetivo de pipeline:
- <= 70 ms en movil para lectura estable.
- Robustez:
- 0 panics en API publica FFI bajo entradas invalidas controladas.

## Matriz de pruebas

| Modulo | Tipo | Casos minimos |
|---|---|---|
| `input` | unit | frame vacio, sample rate 0, frame valido |
| `detector` | unit | senal senoidal estable, silencio, ruido alto, frame corto |
| `smoothing` | unit | convergencia temporal, estabilidad ante saltos bruscos, confidence en [0,1] |
| `ffi` | integration/unit | handle invalido, punteros nulos, json invalido, lifecycle init/process/update/dispose |

## Seguridad basica

- No panic en rutas `tuner_*`.
- Manejo de `null pointer` y `invalid handle` con error code.
- Limpieza de handle en `dispose` sin leaks.

## Ejecucion recomendada

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test
```
