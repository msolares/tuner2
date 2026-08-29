# Protocolo de rechazo de ruido y sonidos no instrumentales (T037)

## Objetivo
Estandarizar la medicion de falsos positivos de `hz`, `note`, `cents`, `confidence` y estados visibles cuando la entrada no corresponde a una cuerda o tono instrumental util.

## Preparacion
- Entorno controlado con registro de ruido base.
- A4 inicial en `440.0 Hz`.
- Probar al menos `chromatic` y `guitar_standard`.
- Registrar build exacta, dispositivo, navegador y configuracion efectiva de captura.
- Registrar configuracion activa (`A4`, preset, `noiseGateDb`, `smoothing`).

## Escenarios obligatorios
1. Silencio de sala (10 s).
2. Voz hablada cerca del micro (30 s).
3. Voz sostenida con vocales (`a`, `e`) (15 s).
4. Aire o soplido directo al micro (10 s).
5. Ventilador/ordenador en reposo (15 s).
6. Ventilador/ordenador bajo carga o ruido continuo equivalente (15 s).
7. Cuerda real aislada como control positivo.
8. Cuerda real con ventilador de fondo como control mixto.
9. Transicion ruido -> cuerda -> ruido para medir enganche y liberacion.

## Datos a registrar por muestra
- `timestampMs`
- `hz`
- `note`
- `cents`
- `confidence`
- preset y plataforma
- sample rate y buffer efectivos
- flags de captura efectivos (`audioSource`, modo iOS, `echoCancellation`, `autoGainControl`, `noiseSuppression`) cuando la plataforma los exponga
- estado visible (`Idle`, `Listening`, `InTune`, `OutOfTune`, `ErrorState`)
- metricas internas en modo debug si existen (`rmsDb`, periodicidad/clarity, candidato bruto, decision de gate tonal)

## Metricas
- Ratio de frames con `hz > 0`.
- Ratio de frames con `confidence >= 0.35`.
- Ratio de frames con `confidence >= 0.60`.
- Numero de locks estables espurios (`note != '--'` durante >= 300 ms).
- Numero de transiciones espurias a `InTune`.
- Tiempo de liberacion desde fin de tono real hasta volver a no deteccion fiable.
- Tiempo de convergencia desde ruido a cuerda real.

## Criterios de aprobacion
- En silencio, `voz`, aire y ventilador no hay transiciones a `InTune`.
- En `guitar_standard`, no hay locks estables espurios >= 300 ms.
- En `chromatic`, pueden aparecer candidatos breves, pero no una lectura confiable sostenida equivalente a lock estable.
- En controles positivos y mixtos, la cuerda real sigue cumpliendo los umbrales de precision de `specs/quality/pitch-accuracy-protocol.md`.
- La liberacion tras perder tono claro ocurre dentro del hold definido y nunca queda bloqueada de forma indefinida.

## Plantilla de reporte
- Plataforma:
- Build:
- Configuracion:
- Flags de captura efectivos:
- Resultado por escenario:
- Ratio `hz > 0`:
- Ratio `confidence >= 0.35`:
- Locks espurios >= 300 ms:
- Transiciones espurias a `InTune`:
- Tiempo de liberacion:
- Hallazgos:
- Acciones correctivas:
