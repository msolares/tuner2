# Corpus polifonico oficial

Este director aloja el corpus versionado de T062. Los audios deben ser PCM crudo,
mono, `f32` little-endian a 48 kHz. `manifest.example.csv` documenta el formato;
el corpus evaluable usa `manifest.csv` y rutas relativas a este directorio.

Cobertura minima:

- C, A, G, E y D mayores abiertos; Am, Em y Dm.
- Power chords en al menos dos fundamentales.
- Positivos con al menos dos guitarras y tres intensidades.
- Negativos de todas las categorias del manifiesto de ejemplo.

Una clase cromatica extra aislada no invalida por si sola un acorde E08. La
categoria `extra_string_substitution` exige que la cuerda extra sustituya un tono
requerido o convierta el voicing en un acorde vecino.

Ejecutar el gate manual cuando exista el corpus:

```text
cargo test --test polyphonic_corpus -- --ignored --nocapture
```

El runner exige recall >= 90%, falsa aceptacion <= 5% y p95 <= 750 ms desde
`attack_ms`. El manifiesto y todos los `.pcm` forman una unica evidencia
versionada; los tonos sinteticos unitarios no sustituyen este gate.
