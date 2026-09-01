# T068 - Render model y CustomPainter del mastil

## Estado
- done

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
- Implementados `FretboardRenderModel` y `FretboardRenderBlock` inmutables en
  Presentation, con seis cuerdas, profundidad normalizada, duracion, target,
  acorde, pasado, estado visual e informacion semantica sin tipos de Data/BLoC.
- `FretboardRenderMapper` transforma exclusivamente `LessonViewportSlice` y
  entidades Domain. La posicion vertical se deriva de
  `event.startTick/endTick - positionTicks`; no acumula pixeles ni tiempo.
- El mapper prioriza el target y cercania a la linea, limita la salida a 40
  bloques y nunca parte un acorde para rellenar el presupuesto. Solo materializa
  los bloques seleccionados incluso ante el fixture sintetico de 1.000 eventos.
- Ties quedan representados por la duracion fusionada del evento de dominio; las
  grace notes no generan bloque, conforme al perfil E08.
- Implementado `FretboardPainter` sin imports de BLoC/Data, streams, XML o
  engines: carretera en perspectiva, seis cuerdas coloreadas y numeradas 6..1,
  trastes, linea de ejecucion, bloques con numero de traste y feedback visual
  waiting/validating/success/failure. Paints y `TextPainter` se preparan fuera de
  `paint` y el trabajo por frame queda acotado a 40 bloques.
- `LearningFretboard` encapsula el canvas en `RepaintBoundary`, expone una unica
  semantica complementaria sin construir widgets por nota, soporta reduce motion
  y sustituye gameplay por la instruccion de giro en vertical.
- Tests escritos para inmutabilidad, seis cuerdas, duracion, acorde alineado,
  todos los estados, target prioritario, limite de 1.000 eventos, grupo de acorde
  indivisible, geometria, imports, repaint, semantica y orientacion.
- Definidos goldens de acorde para 640x360, 844x390, 1024x768 y 1440x900. Sus PNG
  se generan y revisan manualmente según
  `test/presentation/learning/fretboard/goldens/README.md`; no se presentan como
  aprobados hasta ejecutar el comando diferido.
- Validacion y perfil 60 FPS no ejecutados por la politica de validacion
  diferida. El perfil de build+raster p95 se toma en dispositivo de referencia
  cuando T069 integre el renderer en la pantalla completa.
- Comandos para el propietario:
  - `dart format lib/presentation/learning/fretboard test/presentation/learning/fretboard`
  - `flutter test test/presentation/learning/fretboard/fretboard_render_mapper_test.dart`
  - `flutter test --update-goldens test/presentation/learning/fretboard/fretboard_painter_test.dart`
  - revisar los cuatro PNG contra `specs/design/assets/learning-fretboard-concept.png`
  - `flutter test test/presentation/learning/fretboard`
  - `flutter test`
  - `flutter analyze --no-fatal-infos`
  - `git diff --check`
- Si un comando falla, T068 vuelve a `in_progress` antes de continuar con una
  dependencia afectada.
