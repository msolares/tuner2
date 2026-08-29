# Pantalla MVP afinador (T010)

Componentes:
- Tarjeta de estado: `IDLE`, `LISTENING`, `IN TUNE`, `OUT OF TUNE`, `ERROR`.
- Tarjeta de nota: nota detectada y frecuencia en Hz.
- Tarjeta de cents: valor en cents y barra de -50 a +50.
- Controles: permiso (demo), `Start`, `Stop`.
- Calibracion A4: slider con valor visible y boton `Reset`.
- Preset de instrumento: insignia superior con el perfil activo y acceso directo al selector de perfiles MVP (`T052`).

Comportamiento visual:
- Estado `InTune` en verde.
- Estado `OutOfTune` en naranja.
- Estado `ErrorState` en rojo.
- En ausencia de muestra se muestra `--` y `0.00 Hz`.

Reglas de interaccion:
- `Start` habilita escucha solo con permiso concedido.
- `Stop` detiene captura y vuelve a `Idle`.
- La UI se actualiza con cada `PitchSample` recibido por BLoC.
- A4 se ajusta en rango `430.0` a `450.0` Hz.
- Default A4: `440.0` Hz.
- Cambio de A4 se aplica en caliente via evento `UpdateA4`.
- Cambio de preset aplica `noiseGateDb` y `smoothing` segun catalogo.
- Al pulsar la insignia superior del preset se abre un menu anclado con todos los perfiles disponibles y una marca en el activo.
- Elegir un preset usa `SelectPreset` y limpia cualquier afinacion temporal de cancion mediante `SongTuningResultCleared`.
- El panel inferior queda reservado para calibracion A4 y no mantiene un segundo selector de preset.

## Localizacion ES/EN (T053)
- `AppLocalizations` centraliza las cadenas visibles de shell, afinador y metronomo.
- El locale se obtiene automaticamente del navegador o dispositivo mediante `MaterialApp`.
- Cualquier locale `es-*` usa español; `en-*` y los idiomas no soportados usan ingles.
- Los nombres visibles de presets se traducen sin cambiar sus IDs ni configuracion tecnica.
- Mensajes conocidos de BLoC se traducen en presentacion antes de mostrarse.
- La cabecera muestra solo el selector de preset; estado y confidence no se duplican allí (`T054`).
