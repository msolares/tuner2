# T068 - Render model y CustomPainter del mastil

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T058

## Objetivo
Construir el renderer fluido del mastil desde un modelo inmutable, siguiendo la referencia visual y sin introducir reglas musicales.

## Entradas
- `specs/design/learning-fretboard.md`
- `specs/design/assets/learning-fretboard-concept.png`

## Alcance
- Mapper presentation `LessonViewportSlice -> FretboardRenderModel`.
- Proyeccion de seis cuerdas/trastes.
- Bloques de nota/acorde, duracion, ties y grace opcional.
- Linea de ejecucion, target, feedback y estados.
- Ventana visible acotada, paints reutilizados y RepaintBoundary.
- Semantica complementaria fuera del canvas.

## Fuera de alcance
- BLoC, DSP, XML, controles de pantalla o audio.

## Criterios de aceptación
- Seis cuerdas contables y acorde alineado en goldens.
- Painter no importa BLoC/data ni lee streams.
- <= 40 bloques visibles para fixture de 1.000 eventos.
- Presupuesto 60 FPS cumplido en perfil de referencia.

## Evidencia de cierre
- Pendiente.
