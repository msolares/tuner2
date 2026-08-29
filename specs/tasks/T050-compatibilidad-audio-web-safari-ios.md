# T050 - Compatibilidad de audio Web con Safari iOS

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E01, E07

## Dependencias
- T025, T043

## Objetivo
Recuperar la captura del afinador y la salida del metrónomo en Safari iOS mediante una única sesión Web Audio desbloqueada directamente por el gesto del usuario.

## Entradas
- `lib/app/platform_dependencies_web.dart`
- `lib/data/audio/`
- `lib/data/engines/web/`
- `lib/data/metronome/`

## Alcance
- Crear y reutilizar un único `AudioContext` Web para captura y reproducción.
- Reanudar la sesión en la fase de captura de cada gesto táctil/puntero.
- Capturar PCM mono con Web Audio sin depender de un contexto interno creado tarde por un plugin.
- Sintetizar los clics del metrónomo sobre la sesión compartida.
- Liberar streams, tracks y nodos en ciclos start/stop repetidos.
- Mantener intactos los contratos `TunerEngine` y `MetronomeEngine`.

## Fuera de alcance
- Cambios de UI, dominio musical o motores nativos.
- Ejecución con la página en segundo plano o con la pantalla bloqueada.

## Criterios de aceptación
- El primer toque de inicio desbloquea Web Audio antes de procesar el evento BLoC.
- Safari iOS entrega frames PCM reales tras conceder permiso de micrófono.
- El metrónomo produce sonido tras el primer toque y después de volver de segundo plano.
- Afinador y metrónomo no crean contextos Web Audio independientes.
- `flutter analyze`, `flutter test` y build Web quedan en verde.

## Evidencia de cierre
- `flutter build web --no-pub`: correcto; también supera el dry run Wasm.
- Versión de diagnóstico `1.0.4+8` visible como `v1.0.4+8` en la cabecera del afinador y expuesta en el HTML Web.
- Bootstrap Web propio sin registro de service worker; además elimina registros anteriores para impedir que Safari conserve bundles obsoletos.
- Selección de captura por navegador: Safari/iOS usa la sesión Web Audio compartida y Chrome Android/escritorio conserva `record_web`, evitando la regresión de frames observada en Android.
- Restaurada en Chrome Web la configuración de captura PCM16 mono que funcionaba previamente; se eliminan opciones nativas `unprocessed` y buffers personalizados que podían aceptar el micrófono pero entregar silencio.
- Restaurado el `noiseGateDb` del preset guitarra de `-55 dB` a `-60 dB`: una prueba integral reproduce que una E2 de micrófono Web a nivel bajo quedaba totalmente silenciada en guitarra aunque cromático respondía.
- Prueba en navegador local: `v1.0.3` cargada, metrónomo en estado `PLAY` y consola sin errores ni warnings.
- `flutter analyze`: sin errores; permanecen 27 avisos informativos preexistentes fuera del alcance de T050.
- Tests de scheduler y BLoC del metrónomo: 8 tests en verde.
- Suite específica de versión, selección de backend y `WebTunerEngine`: 13 tests en verde. El caso de smoothing usa ahora A3, dentro del rango contractual del preset de guitarra.
- Suite completa Flutter: 86 tests en verde y 1 test condicionado omitido; incluye E2 de bajo nivel y la secuencia Cromático -> Guitarra -> Cromático con el pipeline real.
- Pendiente antes de marcar `done`: desplegar el build y validar físicamente captura y salida en Safari iOS.
