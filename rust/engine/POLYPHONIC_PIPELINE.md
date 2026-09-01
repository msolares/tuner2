# Pipeline polifonico E08

## Propiedad y API

`src/polyphonic.rs` es un front-end DSP Rust interno e independiente del
detector monofonico. No se exporta por FFI en T062 y no decide si el alumno
acierta: devuelve `ChordEvidence` con 12 fortalezas C..B, confidence,
onset confidence y una secuencia monotona de ataques.

## Procesamiento

1. Valida frame, sample rate y finitud sin panic.
2. Calcula RMS, noise gate y subida de energia para onset.
3. Ejecuta un banco Goertzel con ventana Hann entre MIDI 40 y 88.
4. Reduce contribuciones de segundo y tercer armonico desde fundamentales
   inferiores.
5. Proyecta la energia maxima por clase tonal, elimina suelo espectral y
   normaliza a `[0, 1]`.
6. Acumula maximos cromaticos en una ventana de hasta 700 ms para rasgueos.

## Limites

- Analisis espectral: maximo 8192 muestras recientes por llamada.
- Historial: ring buffer fijo de 64 frames cromaticos.
- Ventana de rasgueo: `1..700 ms`.
- Sample rate admitido: `8000..192000 Hz`; el corpus oficial usa PCM mono
  `f32le` a 48000 Hz.
- Sin buffers crecientes ni asignaciones propiedad del analyzer por llamada.
- El test local exige que 20 analisis de 8192 muestras terminen en menos de
  750 ms en debug; no sustituye la medicion p95 en dispositivo de referencia.

## Corpus oficial pendiente

No hay grabaciones PCM versionadas en el repositorio al ejecutar T062. Para
cerrar los gates de producto deben incorporarse grabaciones propias/licenciadas
de dos guitarras y tres intensidades para C, A, G, E y D mayores; Am, Em y Dm;
power chords; y los negativos definidos en
`specs/quality/learning-mode-test-plan.md`.

Los tonos armonicos sinteticos de unit test validan matematicas, limites y
regresiones, pero no cuentan como evidencia de recall, falsa aceptacion ni p95
del corpus oficial.
