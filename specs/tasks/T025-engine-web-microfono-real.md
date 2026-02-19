# T025 - Engine Web con microfono real

## Estado
- todo

## Prioridad
- P1

## Epic
- E01

## Dependencias
- T006, T008, T021

## Objetivo
Implementar `WebTunerEngine` con captura de microfono real y deteccion de pitch en Dart bajo el contrato de dominio.

## Entregables
- Integracion Web Audio API (`getUserMedia`) en `lib/data/engines/web/`.
- Pipeline Dart de deteccion/smoothing compatible con contrato `PitchSample`.
- Manejo de permisos/errores web alineado con politica de errores existente.

## Criterios de aceptacion
- En navegador, la app solicita permiso de microfono y recibe audio real.
- `WebTunerEngine.samples()` emite `PitchSample` continuo con `confidence`.
- El contrato `TunerEngine` y firmas de dominio no se alteran por limitaciones Web.
- Errores de permiso/stream se reflejan en `ErrorState` recuperable cuando aplique.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Variaciones entre navegadores en sample rate efectivo y latencia.

## Evidencia de cierre
- Pendiente.
