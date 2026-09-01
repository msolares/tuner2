# T075 - Sincronizacion de sesion y reentrada con audio

## Estado
- todo

## Prioridad
- P1

## Epic
- E09

## Dependencias
- T074

## Objetivo
Usar el audio como reloj maestro y aplicar pausa/fade/seek/reentrada sin cambiar la semantica educativa E08.

## Entradas
- `specs/epics/E09-audio-real-y-sincronizacion.md`
- UC-L04..UC-L08

## Alcance
- Interpolacion beat map.
- Pausa atomica al target y fade de 50 ms.
- Seek un pulso atras y evaluacion desactivada durante reentrada.
- Auriculares/backing policy y errores recuperables.
- UI de fuente/velocidad sincronizada.

## Fuera de alcance
- Creacion automatica de beat maps o licencias.

## Criterios de aceptación
- Audio/mastil dentro de 40 ms p95.
- No hay target doble ni audio solapado tras reentrada.
- Pausa, seek y cambio de velocidad conservan alineacion.
- Leccion sin audio mantiene flujo E08 intacto.

## Evidencia de cierre
- Pendiente.
