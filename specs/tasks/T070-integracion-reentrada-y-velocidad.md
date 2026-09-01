# T070 - Integracion de cuenta, espera, reentrada y velocidad

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T061, T064, T065, T066, T067, T069

## Objetivo
Completar el flujo educativo extremo a extremo sin audio real, incluyendo cuenta inicial, bloqueo, acierto y reentrada.

## Entradas
- `specs/learning/use-cases.md`
- Contenido T061

## Alcance
- Cuenta exclusivamente visual; E08 no reproduce audio.
- Espera en cada target requerido.
- Reentrada de un pulso.
- Velocidades 50..100%.
- Repetir seccion y final.
- Telemetria local de intentos/precision en memoria.

## Fuera de alcance
- Persistencia de progreso, audio real o scoring competitivo.

## Criterios de aceptación
- Escala y progresion se completan por microfono.
- El target acertado no vuelve a bloquear tras reentrada.
- Cambiar velocidad no desplaza eventos ni pitch.
- Pausa/repeticion no duplica analyzer o clock.

## Evidencia de cierre
- Pendiente.
