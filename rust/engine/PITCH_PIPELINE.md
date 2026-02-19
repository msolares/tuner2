# Pipeline de deteccion pitch (T008)

Objetivo:
- Obtener salida estable de `hz` y `confidence` con latencia apta para UI en tiempo real.

## Algoritmo del detector (MVP)

Entrada:
- Frame PCM `f32`, mono, normalizado.

Pasos:
1. Calcular RMS del frame para detectar nivel util de senal.
2. Estimar frecuencia por `zero-crossing` con umbral anti-ruido.
3. Validar rango de frecuencia util (`50 Hz` a `1200 Hz`).
4. Calcular `periodicity_hint` como proxy de periodicidad.

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
- Error mediano <= `+/- 5 cents` en notas sostenidas (82 Hz a 880 Hz) con señal limpia.
- Latencia objetivo:
- <= `70 ms` para estabilizar lectura visual en movil (3 frames aprox a 48k/1024).
- <= `100 ms` en Web por variacion de buffers del navegador.

## Riesgos conocidos

- `zero-crossing` pierde precision con armónicos fuertes.
- En ruido alto, `confidence` puede caer de forma abrupta.
- El detector final de produccion puede cambiar (autocorrelacion/YIN) sin romper contrato de salida.
