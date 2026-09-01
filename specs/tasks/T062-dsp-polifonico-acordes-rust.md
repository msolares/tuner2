# T062 - DSP polifonico de acordes en Rust

## Estado
- in_progress

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
- Evidencia parcial; la task permanece `in_progress` porque falta el corpus PCM
  oficial obligatorio.
- Implementado `rust/engine/src/polyphonic.rs` como API Rust interna separada:
  banco Goertzel MIDI 40..88, ventana Hann, 12 fortalezas C..B, supresion de
  segundo/tercer armonico, confidence, onset confidence y `onsetSequence`.
- Rasgueos acumulan maximos cromaticos hasta 700 ms en un ring buffer fijo de 64
  frames; cada llamada analiza como maximo 8192 muestras y el analyzer ocupa
  menos de 16 KiB. Entradas vacias/cortas, sample rate invalido y NaN producen
  errores tipados sin panic.
- Tests sintéticos cubren mayores, menores y power chords con dos perfiles
  timbricos y tres intensidades; rasgueo escalonado, ataque repetido, supresion
  armonica, silencio, ruido, NaN, memoria fija y presupuesto local. Los 20
  analisis de 8192 muestras cumplen el limite local de 750 ms en debug.
- `rust/engine/POLYPHONIC_PIPELINE.md` documenta API, algoritmo, limites y
  requisitos exactos del corpus pendiente.
- Añadido runner reproducible en `rust/engine/tests/polyphonic_corpus.rs`: valida
  el manifiesto y su cobertura, decodifica PCM f32le con errores tipados y mide
  recall, falsa aceptacion y p95 desde el ataque con los umbrales oficiales. El
  gate de corpus queda `ignored` por defecto y falla de forma explicita al
  invocarlo sin `testdata/polyphonic/manifest.csv`.
- `rust/engine/testdata/polyphonic/` contiene instrucciones y un manifiesto de
  ejemplo seguro. La spec de calidad aclara que una clase cromatica extra
  aislada no invalida por si sola un acorde, de acuerdo con el contrato E08.
- `cargo fmt --check` -> limpio.
- `cargo clippy --all-targets -- -D warnings` -> limpio.
- `cargo test --all-targets` -> 28 pruebas superadas (24 unitarias Rust y 4 del
  runner), 1 gate de corpus omitido de forma explicita; incluye las 6 pruebas
  polifonicas y todas las regresiones del detector monofonico/FFI.
- ABI preservado: `rust/engine/src/ffi.rs` y las funciones `tuner_*` no se
  modificaron; el unico cambio de modulo existente es `pub mod polyphonic`.
- `git diff --check` -> limpio.
- Bloqueo verificable: no existen archivos `.wav`, `.pcm`, `.raw` o `.flac`
  oficiales en specs, tests, docs ni fuentes Rust. El plan exige grabaciones PCM
  mono 48 kHz de al menos dos guitarras y tres intensidades, y prohibe sustituir
  recall >= 90%, falsa aceptacion <= 5% y p95 <= 750 ms por tonos sinteticos.
  Hasta incorporar corpus propio/licenciado y medir esos gates, T062 no puede
  marcarse `done`; los gates Flutter finales se difieren al cierre.
