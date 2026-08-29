# T051 - Regresion de deteccion continua en todos los presets

## Estado
- done

## Prioridad
- P0

## Epic
- E04, E05

## Dependencias
- T025, T037, T038, T039, T040

## Objetivo
Recuperar la deteccion util y continua de nota, frecuencia y cents desde microfono real, evitando que el pipeline oculte una cuerda sostenida en `chromatic` o en cualquier preset de instrumento.

## Entradas
- `lib/data/audio/`
- `lib/data/engines/common/`
- `lib/data/engines/web/web_tuner_engine.dart`
- `lib/data/engines/mobile/mobile_ffi_tuner_engine.dart`
- `lib/presentation/bloc/tuner_bloc.dart`
- `lib/presentation/screens/tuner_screen.dart`
- `specs/quality/pitch-accuracy-protocol.md`
- `specs/quality/noise-rejection-protocol.md`

## Alcance
- Reproducir y trazar una nota sostenida desde captura hasta UI.
- Identificar la etapa que convierte una deteccion valida en silencio o lectura intermitente.
- Separar candidato tonal, confirmacion inicial, mantenimiento y liberacion para no exigir de nuevo el ataque en cada fluctuacion breve.
- Garantizar una lectura util en `chromatic`, `guitar_standard`, `bass_standard`, `ukulele_standard` y `violin_standard`.
- Mantener rechazo de silencio y ruido sin romper contratos de dominio, BLoC o FFI.
- Agregar pruebas de regresion con señal sostenida, huecos breves, cambios de nota y cambio de preset en caliente.

## Fuera de alcance
- Rediseno visual.
- Cambios de contratos publicos Dart o FFI.
- Clasificacion ML de fuentes de audio.

## Criterios de aceptacion
- Una nota valida sostenida muestra `note`, `hz` y `cents` de forma continua tras una convergencia corta en todos los presets.
- Huecos breves de confianza no borran inmediatamente una lectura estable.
- Un cambio real de nota o cuerda converge sin quedarse bloqueado en la anterior.
- Cambiar preset en caliente reinicia el tracking y vuelve a detectar sin reiniciar la app.
- Silencio y ruido de baja confianza no generan un lock estable espurio.
- Pruebas Dart/Rust relacionadas, `flutter analyze` y build Web quedan validados.
- Existe evidencia de microfono real en navegador para `chromatic` y `guitar_standard`.

## Plan de implementacion
1. Capturar evidencia de UI y observabilidad por etapa con microfono real.
2. Comparar el pipeline actual con la ultima version funcional.
3. Corregir la politica de confirmacion, mantenimiento y liberacion en la etapa responsable.
4. Cubrir todos los presets y transiciones con pruebas deterministas.
5. Validar build, tests y guitarra real en navegador.

## Evidencia de cierre
- Causa raiz reproducida en Web con microfono real: el detector descartaba
  cuerdas graves validas mediante un veto de cruces por cero y el pipeline
  reiniciaba la confirmacion ante huecos breves de confidence.
- Se elimino el veto duro, se reforzo la separacion entre ruido y tono y se
  ajustaron confirmacion, mantenimiento y liberacion para todos los presets.
- El estabilizador mantiene una muestra coherente mientras confirma un cambio
  y nunca mezcla la etiqueta de una nota con los Hz/cents de otra.
- Validacion real en navegador, `guitar_standard`: E2 estable entre 82.4 y
  83.0 Hz y A2 entre 109.8 y 110.7 Hz, con nota, cents y barra activos.
- Validacion real en navegador, `chromatic`: recorrido continuo E2 82.4 Hz,
  A2 110.4 Hz, D3 146.7 Hz, G3 196.7 Hz, B3 247.3 Hz y E4 329.5 Hz. Un
  candidato aislado A1 fue rechazado sin sustituir la lectura A2 estable.
- `flutter test`: 95 pruebas superadas y 1 skip documentado por el harness
  multiplataforma pendiente.
- `cargo test` en `rust/engine`: 18 pruebas superadas.
- `flutter build web --debug --no-wasm-dry-run`: build correcto.
- `flutter analyze --no-fatal-infos`: sin errores ni warnings; permanecen 26
  infos preexistentes de deprecaciones/const fuera del alcance de esta task.
