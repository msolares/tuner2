# Politica de errores (T013)

## Tabla de errores y UX esperada

| Capa | Codigo | Causa tipica | Recuperable | UX esperada |
|---|---|---|---|---|
| permisos | `audio_permission_denied` | usuario deniega microfono | si | mostrar CTA para conceder permiso |
| audio | `audio_device_unavailable` | dispositivo no disponible | si | permitir reintento |
| app/bloc | `engine_start_failed` | fallo al iniciar engine | si | mensaje y boton Start activo |
| app/bloc | `engine_stream_error` | error en stream de muestras | si | detener escucha y permitir Start |
| ffi | `ffi_invalid_handle` | handle invalido | si | reinicializar engine en nuevo Start |
| ffi | `ffi_invalid_frame` | frame corrupto/vacio | si | descartar frame y continuar |
| ffi | `ffi_invalid_sample_rate` | sample rate fuera de contrato | si | fallback de sample rate |
| ffi | `ffi_internal_error` | panic/error interno | no | informar error y reiniciar sesion |
| settings | `settings_persistence_read_failed` | no se pudo leer prefs | si | continuar con defaults |
| settings | `settings_persistence_write_failed` | no se pudo guardar prefs | si | mantener sesion y advertir |
| presets | `unknown_preset` | id de preset no registrado | si | mantener preset actual |
| general | `unexpected_error` | fallback no catalogado | si | mostrar error generico y reintento |

Implementacion:
- Catalogo: `lib/presentation/bloc/tuner_error_policy.dart`
- Consumo en BLoC: `lib/presentation/bloc/tuner_bloc.dart`
- Presentacion de mensaje: `lib/presentation/screens/tuner_screen.dart`
