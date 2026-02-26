# Pipeline de deteccion pitch (T008)

Objetivo:
- Obtener salida estable de `hz` y `confidence` con latencia apta para UI en tiempo real.

## Algoritmo del detector (MVP)

Entrada:
- Frame PCM `f32`, mono, normalizado.

Pasos:
1. Validar frame (`len` minimo y `sample_rate` valido).
2. Calcular RMS y aplicar `noise_gate_db` para cortar detecciones en silencio/ruido bajo.
3. Remover offset DC (centrado por media).
4. Calcular autocorrelacion normalizada en el rango de lags `min_hz..max_hz`.
5. Buscar pico principal por maximo local y aplicar correccion armonica por multiplos de lag.
6. Refinar lag con interpolacion parabolica para reducir error de cuantizacion.
7. Convertir lag a frecuencia (`hz`) y derivar `periodicity_hint` desde la correlacion.

Salida intermedia:
- `Detection { hz, signal_rms, periodicity_hint }`

## Smoothing temporal y confidence

Modelo:
- Filtro exponencial por handle:
- `hz_s(t) = alpha * hz(t) + (1 - alpha) * hz_s(t-1)`
- `alpha` MVP: `0.2`

Confidence compuesta:
- Energia (`signal_rms` normalizada): 45%
- Periodicidad (`periodicity_hint`): 35%
- Estabilidad entre frames (delta en cents): 20%
- Resultado acotado a `[0.0, 1.0]`.

## Objetivos de performance/calidad (MVP)

- Precision objetivo:
- Error mediano <= `+/- 5 cents` en notas sostenidas (82 Hz a 880 Hz) con senal limpia.
- Latencia objetivo:
- <= `70 ms` para estabilizar lectura visual en movil (3 frames aprox a 48k/1024).
- <= `100 ms` en Web por variacion de buffers del navegador.

## Riesgos conocidos

- Senales con armonicos muy dominantes pueden inducir errores de fundamental si no se calibra bien la correccion armonica.
- En ruido alto, `confidence` puede caer de forma abrupta.
- El detector final de produccion puede cambiar (autocorrelacion/YIN/ML) sin romper contrato de salida.
