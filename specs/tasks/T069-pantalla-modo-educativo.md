# T069 - Pantalla responsive del modo educativo

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T061, T067, T068

## Objetivo
Implementar la pantalla horizontal completa con mastil, estado de espera, diagrama de acorde, progreso y controles.

## Entradas
- `specs/design/learning-fretboard.md`
- `lib/app/app_theme.dart`

## Alcance
- Layout movil/tablet/Web.
- Paneles, progreso, compas, velocidad y microfono.
- Estados running/waiting/validating/success/reentry/failure.
- Diagrama de acorde y feedback por clase tonal.
- Accesibilidad, localizacion ES/EN y reduce motion.

## Fuera de alcance
- Nueva identidad visual, audio real o minijuegos.

## Criterios de aceptación
- Jerarquia coincide con la referencia aprobada.
- Sin overflow en tamaños normativos.
- Estado no depende solo de color.
- Cerrar pantalla solicita stop antes de dispose.
- Widget/golden tests en verde.

## Evidencia de cierre
- Implementada `LessonScreen` como adaptador de lifecycle y
  `LessonScreenView` como vista declarativa de `LessonBlocState`. La entrada
  solicita carga, background solicita stop, foreground no reinicia recursos y
  cerrar espera el retorno a un estado inactivo antes de permitir dispose.
- Implementada la jerarquia horizontal completa: cabecera con titulo/seccion,
  progreso, compas y velocidad; panel de estado/target/intento; mastil T068;
  diagrama de acorde; y barra con inicio, pausa/reanudacion, stop, repeticion,
  velocidad 50..100% y estado textual del microfono.
- El layout usa variantes ancha, compacta y estrecha para movil, tablet y Web;
  en vertical sustituye el gameplay por una instruccion de giro. Los tamaños
  640x360, 1024x600 y 1440x900 quedan cubiertos por widget tests y goldens.
- Los estados `running`, `waitingForTarget`, `validating`, `successFeedback`,
  `reentry` y `failure` tienen texto, icono y semantica, por lo que no dependen
  solo del color. `MediaQuery.disableAnimationsOf` gobierna reduce motion.
- Extendida la proyeccion de Presentation para conservar solo la ultima
  `PerformanceObservation` valida del target actual. La vista muestra las doce
  fortalezas crudas C..B requeridas por el acorde y nunca calcula umbrales,
  acierto o fallo; la observacion se limpia en start/stop/repeticion/cambio de
  target/error.
- Extraidos los textos incrustados del mapper T068 y añadida localizacion ES/EN
  para pantalla, controles, estados, semantica, notas y errores tipados.
- Tests escritos para imports de arquitectura, estado crudo del acorde,
  limpieza al detener, estados visuales, controles, ES/EN, semantica,
  orientacion, cierre con stop y ausencia de overflow en tamaños normativos.
- Definidos goldens de pantalla para 640x360, 1024x600 y 1440x900. La generacion
  y revision manual se documentan en
  `test/presentation/learning/screens/goldens/README.md`.
- Validacion diferida por decision del propietario; ningun comando de format,
  test, analyze, build o diff fue ejecutado en esta task.
- Comandos pendientes para el propietario:
  - `dart format lib/app/app_localizations.dart lib/presentation/learning test/presentation/learning`
  - `flutter test test/presentation/learning/bloc/lesson_bloc_test.dart`
  - `flutter test test/presentation/learning/fretboard`
  - `flutter test test/presentation/learning/screens/lesson_screen_test.dart --update-goldens`
  - revisar los tres PNG contra `specs/design/learning-fretboard.md` y la referencia aprobada
  - `flutter test test/presentation/learning/screens/lesson_screen_test.dart`
  - `flutter test`
  - `flutter analyze --no-fatal-infos`
  - `git diff --check`
- Si cualquiera de estos comandos falla, T069 vuelve a `in_progress` antes de
  continuar con una dependencia afectada.
