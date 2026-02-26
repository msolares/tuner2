# Tuner BLoC - Maquina de estados (T009)

Estados publicos:
- `Idle`
- `Listening`
- `InTune`
- `OutOfTune`
- `ErrorState`

Eventos publicos:
- `StartListening`
- `StopListening`
- `UpdateA4`
- `SelectPreset`
- `AudioPermissionChecked`

## Matriz evento -> estado

| Evento | Estado origen | Estado destino | Nota |
|---|---|---|---|
| `AudioPermissionChecked(false)` | cualquiera | `ErrorState` | Recuperable, detiene engine |
| `AudioPermissionChecked(true)` | `ErrorState` | `Idle` | Recuperacion despues de permiso |
| `StartListening` | `Idle`/`ErrorState` | `Listening` | Requiere permiso concedido |
| `StartListening` | cualquiera sin permiso | `ErrorState` | `audio_permission_denied` |
| `StopListening` | `Listening`/`InTune`/`OutOfTune` | `Idle` | Libera suscripcion + stop engine |
| `UpdateA4` | cualquiera | mismo tipo de estado con settings nuevos | Reinicia engine si estaba escuchando |
| `SelectPreset` | cualquiera | mismo tipo de estado con settings nuevos | Reinicia engine si estaba escuchando |
| `sample` interno | `Listening` | `InTune` o `OutOfTune` | Segun cents/confidence |
| `error` interno stream | `Listening`/`InTune`/`OutOfTune` | `ErrorState` | Recuperable |

Regla de afinacion:
- `InTune` cuando `confidence >= 0.6` y `abs(cents) <= 5.0`.

## Song Tuning BLoC (T033)

Estados:
- `SongTuningState` con `idle`, `loading`, `success`, `error`.

Eventos:
- `SongNameChanged`
- `SongTuningSubmitted`

Reglas:
- Boton de consulta habilitado solo cuando hay texto no vacio y no hay request en curso.
- Errores de `SongTuningLookupException` se mapean a mensajes de UI recuperables.
