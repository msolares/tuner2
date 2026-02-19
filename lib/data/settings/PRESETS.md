# Presets MVP (T012)

Lista inicial:
- `chromatic`: `noiseGateDb=-60.0`, `smoothing=0.20`
- `guitar_standard`: `noiseGateDb=-55.0`, `smoothing=0.24`
- `ukulele_standard`: `noiseGateDb=-53.0`, `smoothing=0.22`
- `bass_standard`: `noiseGateDb=-58.0`, `smoothing=0.28`
- `violin_standard`: `noiseGateDb=-50.0`, `smoothing=0.18`

Reglas de uso:
- `SelectPreset` debe actualizar `instrumentPreset`, `noiseGateDb` y `smoothing`.
- Si el engine esta en escucha, el cambio se aplica en caliente con restart controlado.
- Preset desconocido produce `ErrorState` recuperable en BLoC.
