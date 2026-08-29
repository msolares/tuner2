# E07 - Metrónomo configurable

## Objetivo
Incorporar un metrónomo profesional como segundo modo de la aplicación, accesible desde la navegación inferior, sin alterar el comportamiento funcional ni la presentación interna del afinador existente.

## Alcance funcional
- Navegación inferior con dos destinos: `Afinador` y `Metrónomo`.
- Tempo configurable entre 20 y 300 BPM, con controles incremental, deslizador y `tap tempo`.
- Catálogo de compases habituales y opción personalizada.
- Selección del tiempo que actúa como tónica o acento principal.
- Configuración individual de cada tiempo del compás.
- Selección por tiempo de pulso simple, subdivisión binaria, tresillo, subdivisión cuaternaria o silencio.
- Acento audible y visual diferenciado para tónica, pulso normal y pulso silenciado.
- Persistencia local de la última configuración válida.
- Inicio, actualización en caliente y parada sin reiniciar la pantalla.

## Compases soportados

### Presets iniciales
- Simples: `2/4`, `3/4`, `4/4`.
- Irregulares: `5/4`, `7/4`, `5/8`, `7/8`.
- Compuestos: `6/8`, `9/8`, `12/8`.
- Adicionales de uso común: `2/2`, `3/8`, `4/8`, `6/4`.

### Compás personalizado
- Numerador entero de 1 a 16.
- Denominador limitado a potencias musicales válidas: `2`, `4`, `8` o `16`.
- Al cambiar el numerador se conservan los tiempos compatibles, se crean los nuevos con valores por defecto y se eliminan únicamente los que quedan fuera del compás.
- El primer tiempo es la tónica por defecto, pero el usuario puede desplazarla a cualquier tiempo.

La lista de presets es una ayuda de UX, no un límite del dominio. El contrato se basa en numerador y denominador para admitir otros compases válidos.

## Semántica rítmica por tiempo
Cada unidad indicada por el numerador se representa mediante `BeatConfig`:

- `accent`: `strong`, `normal` o `muted`.
- `subdivision`: `single`, `duplet`, `triplet` o `quadruplet`.

La figura mostrada por la UI se calcula respecto a la unidad del denominador. Por ejemplo, en `x/4`, `single` se presenta como negra, `duplet` como dos corcheas, `triplet` como tresillo de corcheas y `quadruplet` como cuatro semicorcheas. Este modelo evita figuras inválidas al trabajar con denominadores distintos de 4.

Reglas:
- Debe existir exactamente un tiempo `strong`, identificado en UI como tónica.
- Un tiempo `muted` conserva su subdivisión, pero no produce sonido; continúa participando en el avance visual.
- El acento se aplica al primer pulso de la subdivisión del tiempo.
- Las subdivisiones restantes usan el sonido secundario.
- El cambio de configuración entra en vigor en el siguiente límite de compás para evitar cortes o pulsos duplicados.

## Contratos de dominio propuestos

```dart
class TimeSignature {
  final int numerator;
  final int denominator;
}

enum BeatAccent { strong, normal, muted }
enum BeatSubdivision { single, duplet, triplet, quadruplet }

class BeatConfig {
  final BeatAccent accent;
  final BeatSubdivision subdivision;
}

class MetronomeSettings {
  final int bpm;
  final TimeSignature timeSignature;
  final List<BeatConfig> beats;
}

class MetronomeTick {
  final int beatIndex;
  final int subdivisionIndex;
  final int timestampMs;
  final BeatAccent accent;
}

abstract class MetronomeEngine {
  Future<void> start(MetronomeSettings settings);
  Future<void> update(MetronomeSettings settings);
  Stream<MetronomeTick> ticks();
  Future<void> stop();
}

abstract class MetronomeSettingsStore {
  Future<MetronomeSettings?> load();
  Future<void> save(MetronomeSettings settings);
}
```

Invariantes:
- `beats.length == timeSignature.numerator`.
- BPM dentro de `20..300`.
- Numerador y denominador dentro del rango soportado.
- Exactamente un tiempo con `BeatAccent.strong`.
- Las entidades son inmutables y validan datos antes de alcanzar el engine.

## Contrato BLoC propuesto

### Eventos
- `MetronomeInitialized`.
- `MetronomeStarted`.
- `MetronomeStopped`.
- `TempoChanged`.
- `TapTempoPressed`.
- `TimeSignatureChanged`.
- `StrongBeatChanged`.
- `BeatAccentChanged`.
- `BeatSubdivisionChanged`.
- `MetronomeTickReceived`.
- `AppLifecycleChanged`.

### Estados
Un único estado inmutable `MetronomeState` con:
- `status`: `initial`, `idle`, `playing` o `failure`.
- `settings`.
- `activeBeatIndex` y `activeSubdivisionIndex`.
- `errorMessage` recuperable.

El BLoC depende solo de `MetronomeEngine` y `MetronomeSettingsStore` del dominio.

## Arquitectura

### Presentation
- `AppShell` será propietario de la navegación inferior.
- `TunerScreen` conservará su contenido y comportamiento; solo dejará de poseer la navegación global.
- `MetronomeScreen` consumirá exclusivamente `MetronomeBloc`.
- Los widgets de edición rítmica no llamarán directamente al engine ni a almacenamiento.
- Se usará `IndexedStack` para conservar la configuración y el estado visual de cada pestaña.

### Domain
- Entidades, validadores y contratos del metrónomo independientes del afinador.
- Ningún contrato existente de `TunerEngine`, pitch, afinación o búsqueda de canciones cambia.
- La conversión de subdivisiones a instantes temporales pertenece al dominio/engine, no a la UI.

### Data móvil
- Scheduler Dart en `data` basado en reloj monotónico y objetivos temporales absolutos.
- `Timer` se usa únicamente para despertar el siguiente pulso; no se usa `Timer.periodic` ni se acumula el error de callbacks anteriores.
- Los clics se sintetizan como PCM/WAV en runtime y se precargan una sola vez en pools separados para acento fuerte y normal mediante el backend nativo de baja latencia.
- Ningún pulso puede volver a preparar o reasignar su fuente de audio. Las operaciones en vuelo están acotadas, observan sus errores y se drenan de forma limitada durante `stop`.
- Si el isolate despierta con uno o más pulsos completos de retraso, el scheduler avanza el calendario sin reproducir una ráfaga de clics vencidos.
- El sink móvil escribe las muestras en un directorio temporal privado y lo elimina en cada `stop`.
- Los recursos del afinador y del metrónomo no se comparten.
- Rust permanece como motor DSP del afinador; el metrónomo no introduce procesamiento de señal que justifique ampliar el ABI FFI.

### Data Web
- Implementación Dart del mismo `MetronomeEngine`.
- El mismo scheduler monotónico y pools Web precargados con muestras WAV en `data:` URI.
- El backend Web aplica los mismos límites de operaciones en vuelo y recuperación sin ráfagas que el backend móvil.
- Los `MetronomeTick` visuales se emiten desde el calendario absoluto del engine, no desde repaints de UI.

### Persistencia
- Adaptador basado en `SharedPreferences` para la última configuración.
- Datos versionados para permitir migraciones posteriores.
- Una configuración corrupta restaura `120 BPM`, `4/4`, primer tiempo fuerte y pulsos simples.

## Navegación y ciclo de vida
- La aplicación inicia en `Afinador` para conservar el flujo actual.
- Al cambiar de pestaña se detiene de forma ordenada el modo saliente; su configuración permanece en memoria.
- No se permite capturar micrófono y reproducir el metrónomo simultáneamente en este alcance, evitando realimentación y conflictos de audio focus.
- Al pasar la app a segundo plano se detiene el modo activo y se liberan recursos.
- Start/stop repetido debe ser idempotente y no duplicar streams, schedulers ni handles.

## UX de la pantalla
- Cabecera consistente con la identidad visual de WeBand.
- BPM como dato principal, con botones `-`/`+`, deslizador y `TAP`.
- Selector de compás con presets y editor personalizado.
- Secuencia horizontal/adaptativa de tiempos numerados.
- Cada tiempo muestra su figura/subdivisión y si es tónica, normal o silencio.
- Un toque selecciona el tiempo; controles accesibles permiten cambiar tónica, acento y figura.
- Indicador de reproducción resalta el pulso y la subdivisión activos sin depender del repaint para producir audio.
- Botón principal start/stop coherente con el afinador.

## Accesibilidad
- Targets táctiles mínimos de 48 dp.
- Etiquetas semánticas para número de tiempo, figura y acento.
- El estado activo no depende solo del color.
- Compatibilidad con escalado de texto y orientación vertical/horizontal.
- Feedback háptico opcional queda fuera del MVP y no reemplaza el audio.

## Calidad y presupuestos técnicos
- Desviación media del pulso respecto al calendario de audio: <= 10 ms.
- Jitter p95 entre pulsos: <= 15 ms en dispositivos objetivo y navegador soportado.
- Sin deriva acumulada superior a 20 ms tras 10 minutos a 120 BPM.
- Cambios en caliente sin doble clic, pérdida de compás o crash.
- Pruebas de dominio para todas las invariantes y transiciones de compás.
- Pruebas BLoC para eventos, persistencia, errores y `tap tempo`.
- Pruebas de widgets para navegación, edición de cada tiempo y accesibilidad básica.
- Pruebas de integración para Android, iOS y Web con evidencia por plataforma.

## Fuera de alcance
- Polirritmos, swing, clave, compases encadenados o cambios automáticos de tempo.
- Biblioteca de sonidos, control de volumen por tiempo o importación de muestras.
- Ejecución persistente en segundo plano o con pantalla bloqueada.
- Sincronización MIDI, Ableton Link, Bluetooth o reloj externo.
- Reproducción simultánea del afinador y metrónomo.

## Criterios de aceptación del epic
- El usuario cambia entre afinador y metrónomo desde la navegación inferior.
- El afinador conserva sus contratos, UI y pruebas funcionales existentes.
- El metrónomo reproduce todos los presets y compases personalizados válidos.
- El usuario puede elegir la tónica y la subdivisión de cada tiempo.
- La representación visual permanece sincronizada con el audio dentro de los presupuestos definidos.
- La configuración se recupera tras reiniciar la aplicación.
- Start/stop, cambios de pestaña y cambios de ciclo de vida limpian los recursos.
- `flutter analyze`, `flutter test` y `cargo test` quedan en verde.

## Riesgos y mitigaciones
- **Jitter por timers de UI:** scheduler monotónico con objetivos absolutos, pool de reproductores y medición física antes de release.
- **Diferencias móvil/Web:** mismo contrato de dominio, suites de conformidad por adaptador y métricas equivalentes.
- **Ambigüedad de figuras en distintos denominadores:** subdivisiones relativas a la unidad del compás y notación calculada en UI.
- **Editor complejo en pantallas pequeñas:** selección de un tiempo y edición contextual, con secuencia desplazable/adaptativa.
- **Conflictos de audio con el afinador:** exclusión mutua y parada explícita al cambiar de modo.
