# Plan de pruebas Dart (T014)

## Objetivo de cobertura

- `lib/domain/**`: >= 90% lineas.
- `lib/presentation/bloc/**`: >= 85% lineas.
- `lib/presentation/screens/**`: >= 70% lineas (widget tests smoke + estados criticos).
- `lib/data/**` (implementaciones Dart/Web/settings): >= 75% lineas.

## Matriz de casos por componente

| Componente | Tipo | Casos minimos |
|---|---|---|
| `PitchSample` | unit | constructor, `copyWith`, `toString` |
| `TunerSettings` | unit | defaults, normalizacion A4, `copyWith` |
| `TunerBloc` | bloc/unit | start/stop, permiso denegado, `UpdateA4` en caliente, `SelectPreset`, transicion `InTune/OutOfTune`, errores recuperables |
| `WebTunerEngine` | unit | `start/samples/stop` y cierre de recursos |
| `SharedPreferencesA4CalibrationStore` | unit | read/write, clamp de rango, fallback por error |
| `TunerScreen` | widget | render estado idle, render error, controles Start/Stop, slider A4, selector preset |

## Escenarios obligatorios

- Nota sostenida estable.
- Cambios rapidos de nota.
- Ruido ambiente (confidence baja).
- Cambio de A4 en caliente.
- Permisos denegados con recuperacion.

## Ejecucion recomendada

```bash
flutter analyze
flutter test test/domain
flutter test test/presentation
flutter test test/data
flutter test
```
