# Protocolo de precision de pitch (T030)

## Objetivo
Estandarizar la medicion de precision y estabilidad de `hz`, `note` y `cents` del afinador en Android, iOS y Web.

## Preparacion
- Entorno silencioso o controlado.
- Volumen de entrada estable (sin clipping).
- A4 inicial en `440.0 Hz` salvo cuando se pruebe cambio de calibracion.
- Preset de instrumento acorde al caso (`chromatic` para baseline).
- Version exacta de app/build registrada en evidencia.

## Referencia de comparacion
- Opcion A: generador de tonos calibrado (seno puro) con frecuencias objetivo.
- Opcion B: afinador externo confiable (hardware/app profesional) como referencia secundaria.
- Recomendado: usar A + B cuando sea posible.

## Matriz minima de frecuencias
- E2 = 82.41 Hz
- A2 = 110.00 Hz
- D3 = 146.83 Hz
- G3 = 196.00 Hz
- A3 = 220.00 Hz
- E4 = 329.63 Hz
- A4 = 440.00 Hz
- C5 = 523.25 Hz

## Escenarios obligatorios
1. Nota sostenida estable (minimo 5 s por frecuencia).
2. Cambios rapidos de nota (secuencia de al menos 5 cambios).
3. Ruido ambiente controlado (baja confidence esperada).
4. Cambio de A4 en caliente (440 -> 442 -> 438).
5. Permisos denegados y recuperacion.

## Datos a registrar por muestra
- `timestampMs`
- `hz`
- `note`
- `cents`
- `confidence`
- frecuencia objetivo o nota esperada
- plataforma/dispositivo/navegador

## Metricas
- Error absoluto en cents por muestra.
- Mediana de error absoluto (objetivo <= 5 cents).
- Percentil 95 de error absoluto (objetivo <= 15 cents).
- Jitter en cents para nota sostenida (desviacion estandar).
- Latencia de convergencia al cambiar de nota.

## Criterios de aprobacion
- Cumplir umbrales de mediana y p95 en escenarios controlados.
- Sin crashes ni bloqueo en start/stop repetido.
- Manejo de permisos/errores coherente con politica vigente.

## Plantilla de reporte
- Plataforma:
- Build:
- Configuracion (A4/preset/noiseGate/smoothing):
- Resultado por escenario:
- Mediana abs cents:
- P95 abs cents:
- Jitter cents (stddev):
- Hallazgos:
- Acciones correctivas:
- Decision: Go / No-Go
