# AGENTS.md - Proyecto Afinador

## 1) Contexto de producto
Aplicacion afinador con deteccion de pitch en tiempo real.

### Objetivo MVP
- Captura de audio desde microfono.
- Deteccion de frecuencia/nota.
- Indicador de desviacion en cents.
- Estado `in tune` o `out of tune`.
- Calibracion A4 configurable.
- Presets basicos de instrumento.

### Plataformas objetivo
- Android.
- iOS.
- Web.

## 2) Arquitectura oficial
Arquitectura target: Flutter + Rust FFI, con implementacion Web en Dart bajo el mismo contrato de dominio.

### Stack
- UI/App shell: Flutter.
- Estado: BLoC.
- Motor pitch en movil: Rust expuesto por FFI.
- Motor pitch en Web: implementacion Dart equivalente.

### Capas y ownership
- `lib/presentation`: pantallas, widgets, BLoC y mappers UI.
- `lib/domain`: entidades, contratos, casos de uso.
- `lib/data`: implementaciones concretas (audio/ffi/adaptadores).

### Reglas de dependencia
- `presentation -> domain` permitido.
- `domain -> data` no permitido.
- `data -> domain` permitido solo para implementar contratos.

## 3) Contratos tecnicos que no deben romperse

### Contratos Dart (dominio)
- `PitchSample { hz, note, cents, confidence, timestampMs }`
- `TunerSettings { a4Hz, instrumentPreset, noiseGateDb, smoothing }`
- `abstract class TunerEngine`
- `Future<void> start(TunerSettings settings)`
- `Stream<PitchSample> samples()`
- `Future<void> stop()`

### Contrato BLoC (aplicacion)
- Eventos: `StartListening`, `StopListening`, `UpdateA4`, `SelectPreset`, `AudioPermissionChecked`.
- Estados: `Idle`, `Listening`, `InTune`, `OutOfTune`, `ErrorState`.

### Contrato Rust FFI (movil)
- `tuner_init(config_json_ptr) -> handle`
- `tuner_process_frame(handle, pcm_ptr, len, sample_rate) -> pitch_result`
- `tuner_update_config(handle, config_json_ptr) -> error_code`
- `tuner_dispose(handle) -> error_code`

### Compatibilidad Web
- Debe implementar el mismo `TunerEngine` en Dart.
- No se permite cambiar firma de dominio solo por limitaciones de Web.

## 4) Flujo de trabajo para agentes
1. Leer `specs/README.md`.
2. Elegir una task de `specs/tasks/` en estado `todo`.
3. Leer el epic asociado en `specs/epics/`.
4. Implementar solo el alcance de la task.
5. Ejecutar pruebas relacionadas.
6. Registrar evidencia en la task.
7. Marcar task como `done`.

## 5) Reglas de ejecucion por task
- No abrir decisiones nuevas si la task ya las fija.
- Si falta una definicion contractual, detener implementacion y actualizar spec primero.
- No mezclar dos tasks en un mismo cambio.
- Mantener cambios pequenos y verificables.

## 6) Calidad y validacion minima

### Checklist tecnico obligatorio
- Lint limpio.
- Tests existentes en verde.
- Nuevos tests agregados cuando cambie logica.
- Manejo de errores sin crash.
- Limpieza de recursos en start/stop repetido.

### Escenarios obligatorios de producto
- Nota sostenida estable.
- Cambios rapidos de nota.
- Ruido ambiente (confidence baja).
- Cambio de A4 en caliente.
- Permisos denegados con recuperacion.

## 7) Politica de contratos
- Todo cambio de contrato debe actualizar `specs/epics` afectados.
- Todo cambio de contrato debe actualizar tasks relacionadas.
- Todo cambio de contrato debe actualizar este `AGENTS.md` si cambia una regla global.

## 8) Convenciones de backlog
- IDs tasks: `T001`, `T002`, ...
- Estados: `todo`, `in_progress`, `blocked`, `done`.
- Prioridades: `P0`, `P1`, `P2`.

## 9) Prompt template para agentes (implementacion)
Usar este formato al iniciar una task:

```
Task: T0XX
Objetivo: <copiar de la task>
Entradas: <archivos y contratos involucrados>
Salida esperada: <entregable concreto>
Tests: <que validar>
Evidencia: <que registrar al cerrar>
```

## 10) Fuentes de verdad
- Planificacion: `specs/`.
- Reglas operativas de agentes: `AGENTS.md`.
- Codigo fuente: `lib/`.

## 11) Operativa de calidad y release (E05)

### Planes de prueba oficiales
- Dart: `specs/quality/dart-test-plan.md`.
- Rust: `specs/quality/rust-test-plan.md`.
- Integracion FFI: `specs/quality/ffi-integration-test-plan.md`.
- Web: `specs/quality/web-compat-matrix.md`.

### Gates de merge
- Pipeline CI: `.github/workflows/ci.yml`.
- Reglas de gate: `specs/quality/ci-gates.md`.
- No cerrar task de calidad si no existe evidencia enlazada en la task.

### Release MVP
- Checklist Go/No-Go: `specs/quality/release-checklist-mvp.md`.
- Evidencia minima por plataforma obligatoria antes de release.

### Protocolo de cierre por task
1. Implementar alcance exacto.
2. Registrar evidencia en `## Evidencia de cierre`.
3. Marcar `## Estado` en `done`.
4. No dejar decisiones abiertas en la task.
