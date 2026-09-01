# AGENTS.md - Afinador y aprendizaje musical

Este archivo es un contrato operativo vivo. Debe actualizarse en la misma task que cambie una regla global, un limite de capa o un contrato publico. Los detalles de una feature viven en `specs/`; aqui solo se mantienen reglas transversales y contratos protegidos.

## 1) Contexto de producto

Aplicacion musical multiplataforma con afinadores, metronomo y una evolucion educativa de guitarra basada en MusicXML, reconocimiento de notas/acordes y mastil virtual.

### Objetivo MVP
- Captura de audio desde microfono.
- Deteccion de frecuencia/nota.
- Indicador de desviacion en cents.
- Estado `in tune` o `out of tune`.
- Calibracion A4 configurable.
- Presets basicos de instrumento.

### Evolucion educativa aprobada

- Lecciones y canciones descritas por MusicXML.
- Modo de espera: la linea temporal se detiene hasta reconocer el objetivo.
- Notas individuales y acordes dirigidos por un target conocido.
- Mástil virtual Flutter fluido en horizontal.
- Acceso desde un tercer destino inferior `Clases` y catalogo local inicial tipo recorrido.
- Velocidad educativa 50..100%.
- Audio real sincronizado en E09; juegos posteriores quedan fuera de E08/E09.
- Las ramas/versiones actuales de los afinadores se preservan; el desarrollo educativo parte de una rama creada por el propietario del proyecto.
- La nomenclatura de esta rama es neutral: no reutilizar marcas, prefijos, nombres de tema ni metadata reservados a otras ramas.

### Plataformas objetivo
- Android.
- iOS.
- Web.

## 2) Arquitectura oficial

Arquitectura obligatoria: Flutter + Rust FFI, con implementacion Web en Dart bajo el mismo contrato de dominio. La especificacion normativa completa es `specs/architecture/clean-architecture.md`.

### Stack
- UI/App shell: Flutter.
- Estado: BLoC.
- Motor pitch en movil: Rust expuesto por FFI.
- Motor pitch en Web: implementacion Dart equivalente.
- Mástil educativo: Flutter `CustomPainter`; Flame queda reservado para minijuegos posteriores.
- Contenido educativo: MusicXML decodificado en data a un modelo de dominio canonico.

### Capas y ownership
- `lib/presentation`: pantallas, widgets, BLoC y mappers UI.
- `lib/domain`: entidades, contratos, casos de uso y maquinas de estado puras.
- `lib/data`: implementaciones concretas (audio/ffi/adaptadores).
- `lib/app`: composition root, navegacion y wiring por plataforma.
- `rust/engine`: DSP y C ABI; nunca reglas pedagogicas o UI.

### Reglas de dependencia
- `presentation -> domain` permitido.
- `domain -> data` no permitido.
- `data -> domain` permitido solo para implementar contratos.
- `presentation -> data` prohibido.
- `domain -> Flutter/XML/FFI/plugins` prohibido.
- `data -> presentation` prohibido.
- `app` es el unico lugar que instancia adaptadores concretos.
- Para nuevas features, el BLoC depende de casos de uso; no reproduce reglas de negocio.
- No crear `helpers/utils/common/shared` para evadir ownership.

### Reglas de tiempo y render

- El reloj musical, nunca el repaint, gobierna la sesion.
- El chart usa ticks enteros; presentation puede interpolar, pero no acumula tiempo de dominio.
- El painter recibe un render model inmutable y no accede a BLoC, streams, XML o engines.
- DSP y parseo nunca se ejecutan en el hilo/frame de UI.

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

### Contratos Dart (metronomo)
- `TimeSignature { numerator, denominator }`
- `BeatConfig { accent, subdivision }`
- `MetronomeSettings { bpm, timeSignature, beats }`
- `MetronomeTick { beatIndex, subdivisionIndex, timestampMs, accent }`
- `abstract class MetronomeEngine`
- `Future<void> start(MetronomeSettings settings)`
- `Future<void> update(MetronomeSettings settings)`
- `Stream<MetronomeTick> ticks()`
- `Future<void> stop()`
- La implementacion del metronomo debe respetar las mismas capas y el mismo contrato en movil y Web.

### Contrato Rust FFI (movil)
- `tuner_init(config_json_ptr) -> handle`
- `tuner_process_frame(handle, pcm_ptr, len, sample_rate) -> pitch_result`
- `tuner_update_config(handle, config_json_ptr) -> error_code`
- `tuner_dispose(handle) -> error_code`

### Compatibilidad Web
- Debe implementar el mismo `TunerEngine` en Dart.
- No se permite cambiar firma de dominio solo por limitaciones de Web.

### Contratos educativos protegidos (E08)

Fuentes normativas:

- `specs/learning/domain-contracts.md`.
- `specs/learning/use-cases.md`.
- `specs/learning/musicxml-profile.md`.
- `specs/design/learning-fretboard.md`.

Invariantes globales:

- `lessonTicksPerQuarter = 960`.
- `LessonChart` es inmutable y no contiene XML ni milisegundos como autoridad.
- `PerformanceAnalyzer` es independiente de `TunerEngine`.
- El analyzer produce evidencia; dominio decide acierto/fallo.
- Los acordes E08 se evaluan contra un target conocido mediante 12 fortalezas cromaticas.
- La posicion cuerda/traste es recomendada; el microfono valida sonido, no digitacion fisica.
- Start/stop/setTarget son idempotentes y movil/Web comparten semantica.
- E08 no inventa progreso, bloqueos ni usuario: UC-L00 lista clases locales disponibles y la persistencia remota se especificara antes de incorporarla.

### Audio real protegido (E09)

- `specs/epics/E09-audio-real-y-sincronizacion.md`.
- El audio es opcional y E08 debe funcionar sin construir un reproductor.
- E08 no reproduce audio ni click; sus cuentas son visuales.
- Con audio, la posicion del reproductor es reloj maestro mediante beat map.
- El time-stretch conserva pitch y solo admite 50..100% inicialmente.
- No se reproduce audio y se valida por altavoz sin politica explicita de auriculares/backing.

## 4) Flujo de trabajo para agentes
1. Leer `specs/README.md`.
2. Elegir una task de `specs/tasks/` en estado `todo`.
3. Leer el epic asociado en `specs/epics/`.
4. Leer las specs enlazadas en `## Entradas` y la skill aplicable.
5. Marcar la task `in_progress` antes de implementar.
6. Implementar solo el alcance de la task.
7. Ejecutar gates relacionados y el conjunto completo exigido por la task.
8. Registrar evidencia verificable en la task.
9. Marcar task como `done` solo sin decisiones abiertas.
10. Al cerrar un bloque o antes de cambiar de ventana, actualizar `specs/handoffs/current.md`.

## 5) Reglas de ejecucion por task
- No abrir decisiones nuevas si la task ya las fija.
- Si falta una definicion contractual, detener implementacion y actualizar spec primero.
- No mezclar dos tasks en un mismo cambio.
- Mantener cambios pequenos y verificables.
- No adelantar dependencias en estado `todo`, `in_progress` o `blocked` salvo actualizacion explicita de plan/spec.
- No cambiar contratos protegidos como efecto colateral.
- No cerrar una task con tests omitidos sin registrar bloqueo.
- Los archivos no relacionados y cambios previos del usuario se preservan.

## 6) Calidad y validacion minima

### Checklist tecnico obligatorio
- Lint limpio.
- Tests existentes en verde.
- Nuevos tests agregados cuando cambie logica.
- Manejo de errores sin crash.
- Limpieza de recursos en start/stop repetido.
- `git diff --check` limpio.
- Tests de arquitectura/imports para capas nuevas.
- Conformidad movil/Web cuando se implementa un mismo puerto.

### Escenarios obligatorios de producto
- Nota sostenida estable.
- Cambios rapidos de nota.
- Ruido ambiente (confidence baja).
- Cambio de A4 en caliente.
- Permisos denegados con recuperacion.
- Nota repetida exige ataque nuevo en modo educativo.
- Acorde completo/incompleto y ruido no generan falsos aciertos.
- Espera, reentrada, cambio de velocidad y repeticion de seccion.
- Navegacion/lifecycle sin recursos duplicados.

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

Antes de editar, el agente debe declarar el mapa previsto de archivos por capa. Si un archivo no encaja en una capa, la implementacion se detiene y se corrige la spec.

## 10) Fuentes de verdad

Precedencia:

1. Contratos globales: `AGENTS.md` y `specs/architecture/clean-architecture.md`.
2. Contrato de feature: epic y specs enlazadas.
3. Alcance ejecutable: task.
4. Codigo y tests implementan los anteriores; no los redefinen.

Si dos fuentes discrepan, no se elige una interpretacion: se detiene la task y se corrige la fuente de mayor nivel.

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

## 12) Skills de repositorio

Codex descubre automaticamente las skills bajo `.agents/skills`:

- `$project-clean-architecture`: obligatoria para diseñar, implementar, refactorizar o revisar codigo del proyecto.
- `$spec-task-executor`: obligatoria al ejecutar o cerrar una task `T0XX`.
- `$guitar-learning-mode`: obligatoria para MusicXML, mastil, lecciones, reconocimiento de notas/acordes o audio sincronizado.

Si aplican varias, se usan en este orden: arquitectura, task, feature.

## 13) Continuidad entre ventanas

- `specs/handoffs/current.md` es el punto de reanudacion operativo; no sustituye AGENTS, epics, specs ni tasks.
- Al recibir `sigue con el desarrollo`, leer primero AGENTS y el handoff, comprobar rama/worktree y continuar la task indicada o iniciar la siguiente si la anterior esta `done`.
- El handoff registra ultimo bloque cerrado, gates, deuda conocida, siguiente task, lecturas y skills obligatorias.
- Actualizarlo al cerrar cada task, antes de una pausa prolongada o cuando cambie el siguiente paso.
- Nunca declarar trabajo completo solo en el handoff: la evidencia y el estado oficial permanecen en la task.

## 14) Atajos prohibidos

- Importar data desde presentation.
- Poner reglas de acierto o timing en widgets/BLoC.
- Parsear MusicXML fuera de data.
- Hacer que Rust conozca lecciones, compases visuales o puntuacion.
- Cambiar `TunerEngine` para devolver acordes.
- Usar el frame de UI como clock.
- Duplicar la implementacion movil/Web con semanticas distintas.
- Aceptar silenciosamente contenido fuera del perfil MusicXML.
- Introducir Unity para el mastil E08/E09.
