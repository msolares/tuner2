# Pantalla MVP afinador (T010)

Componentes:
- Tarjeta de estado: `IDLE`, `LISTENING`, `IN TUNE`, `OUT OF TUNE`, `ERROR`.
- Tarjeta de nota: nota detectada y frecuencia en Hz.
- Tarjeta de cents: valor en cents y barra de -50 a +50.
- Controles: permiso (demo), `Start`, `Stop`.
- Calibracion A4: slider con valor visible y boton `Reset`.
- Preset de instrumento: selector con perfiles MVP.

Comportamiento visual:
- Estado `InTune` en verde.
- Estado `OutOfTune` en naranja.
- Estado `ErrorState` en rojo.
- En ausencia de muestra se muestra `--` y `0.00 Hz`.
- Indicador de confidence visible en porcentaje.

Reglas de interaccion:
- `Start` habilita escucha solo con permiso concedido.
- `Stop` detiene captura y vuelve a `Idle`.
- La UI se actualiza con cada `PitchSample` recibido por BLoC.
- A4 se ajusta en rango `430.0` a `450.0` Hz.
- Default A4: `440.0` Hz.
- Cambio de A4 se aplica en caliente via evento `UpdateA4`.
- Cambio de preset aplica `noiseGateDb` y `smoothing` segun catalogo.
