# Captura de audio por plataforma (T007)

Fuente de parametros MVP para captura de microfono por plataforma.

| Plataforma | Sample rate objetivo | Buffer (frames) | Canales | PCM | Restricciones |
|---|---:|---:|---:|---|---|
| Android | 48000 Hz | 1024 | 1 | Float32 | Fallback a 44100 Hz si hardware no soporta 48000 Hz |
| iOS | 48000 Hz | 1024 | 1 | Float32 | AVAudioSession puede ajustar buffer real por latencia |
| Web | 48000 Hz | 2048 | 1 | Float32 | Navegador define sample rate final y exige permiso/gesto usuario |

Archivo de referencia ejecutable:
- `lib/data/audio/audio_capture_profile.dart`
