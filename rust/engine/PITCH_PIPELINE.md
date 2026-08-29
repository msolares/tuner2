# Pipeline de deteccion pitch (T038)

Objetivo:
- Obtener salida estable de `hz` y `confidence` con latencia apta para UI en tiempo real.

## Algoritmo del detector (actual)

Entrada:
- Frame PCM `f32`, mono, normalizado.

Pasos:
1. Validar frame (`len` minimo y `sample_rate` valido).
2. Calcular RMS y aplicar `noise_gate_db` para cortar detecciones en silencio/ruido bajo.
3. Remover offset DC (centrado por media).
4. Ejecutar un detector basado en `CMNDF` (familia YIN) sobre el rango de lags `min_hz..max_hz`.
5. Extraer varios candidatos fuertes por frame a partir de minimos locales del `CMNDF`.
6. Puntuar candidatos con:
   - `clarity` (1 - `CMNDF`),
   - penalizacion armonica si existe un candidato fuerte en un lag multiple compatible,
   - pequeno sesgo a favor de la fundamental mas grave cuando la familia armonica es plausible.
7. Ejecutar una pasada adicional a media resolucion para graves (`E2`, `A2`) cuando el rango lo justifica.
8. Resolver el mejor candidato entre resoluciones, refinar lag con interpolacion parabolica y convertir a `hz`.
9. Derivar `periodicity_hint` desde `clarity`, separacion frente al segundo mejor candidato y coherencia por `zero crossing`.

Salida intermedia:
- `Detection { hz, signal_rms, periodicity_hint, clarity, candidate_count }`

## Smoothing temporal y confidence

Modelo:
- Filtro exponencial por handle:
- `hz_s(t) = alpha * hz(t) + (1 - alpha) * hz_s(t-1)`
- `alpha` MVP: `0.2`

Confidence compuesta:
- Energia (`signal_rms` normalizada): 40%
- Fuerza tonal (`periodicity_hint` + `clarity`): 40%
- Estabilidad entre frames (delta en cents): 20%
- Penalizacion ligera si el detector devuelve varios candidatos fuertes competidores.
- Resultado acotado a `[0.0, 1.0]`.

## Objetivos de performance/calidad (MVP)

- Precision objetivo:
- Error mediano <= `+/- 5 cents` en notas sostenidas (82 Hz a 880 Hz) con senal limpia.
- Latencia objetivo:
- <= `70 ms` para estabilizar lectura visual en movil (3 frames aprox a 48k/1024).
- <= `100 ms` en Web por variacion de buffers del navegador.

## Riesgos conocidos

- Senales con armonicos extremos todavia pueden requerir tracking temporal adicional por cuerda.
- En ruido alto, `confidence` puede caer de forma abrupta si la separacion entre candidatos es baja.
- La paridad exacta con Web depende de portar esta misma logica en `T039`.
