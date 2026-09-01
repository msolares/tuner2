# Handoff actual

## Punto de reanudacion

- Rama: `aprendizaje-musical`.
- Ultimo bloque cerrado: T065 - PerformanceAnalyzer Web equivalente (`done`,
  validacion incremental diferida por decision del propietario).
- T062 permanece `in_progress` por el corpus PCM real aplazado por autorizacion
  explicita del propietario para probar primero la app sin musica.
- T022 permanece `todo` por validacion fisica Android/iOS aplazada de forma
  explicita; no invalida el cierre tecnico de T064.
- Siguiente task: T066 - clock de practica monotonico.
- Estado esperado del worktree al reanudar: cambios acumulados de T058..T061 sin
  commit; comprobar siempre con `git status --short` y preservar cualquier cambio
  ajeno.

## Realizado

- Implementado `MusicXmlLessonChartDecoder` y normalizador 960 PPQ en Data sin
  filtrar DTOs ni tipos XML fuera del adaptador.
- Cubiertos cursor temporal, exclusión del pentagrama estándar duplicado,
  conversion exacta, ties, acordes, grace, tempo/meter maps, secciones y limites
  irregulares de medida.
- Repeats y endings 1/2 se expanden linealmente con IDs de instancia unicos;
  resolucion no exacta, medidas fuera de tolerancia y navegacion no soportada
  producen errores tipados.
- El fixture inicial genera 23 notas y 23040 ticks. El fixture real genera 874
  eventos y 620160 ticks, con 5 grace ignoradas y 3 medidas normalizadas.
- Corregido en el perfil MusicXML el conteo normativo de 436/872 a 437/874 tras
  documentar los 455 elementos, 5 grace, 1 chord member y 12 tie stop.
- Implementado `AssetLessonCatalog` con metadata normativa, asset privado y
  carga por los puertos UC-L00/UC-L01; la primera clase produce 23 notas, 23040
  ticks y cero diagnosticos.
- Implementado el front-end polifonico Rust interno con evidencia C..B, onset,
  control de armonicos y memoria acotada; ABI/afinador monofonico intactos.
- Preparado el runner oficial de corpus, su manifiesto versionado y validaciones
  de cobertura/PCM/recall/FAR/p95; solo faltan las grabaciones reales.
- Implementado y documentado ABI v1 `performance_*` separado, con layouts fijos,
  observaciones nota/acorde, lifecycle, validacion y tests de integración.
- Implementado el adaptador movil Dart de T064 sobre `AudioFrameSource` y el ABI
  v1, con ownership completo, mapeo de dominio y rollback tras errores.
- Implementado el adaptador Web y su kernel Dart para evidencia dirigida de nota
  y acorde, con chroma C..B, onset, ventana fija, procesamiento cooperativo y
  backlog de un frame.
- Desde T065 rige la validacion diferida solicitada por el propietario: los
  agentes escriben tests y entregan comandos, pero no los ejecutan por task; un
  fallo posterior reabre la task.

## Evidencia vigente

- `flutter test test/data/learning`: 23 passed.
- `flutter test`: 173 passed, 1 skip preexistente.
- `flutter analyze --no-fatal-infos`: exit 0; 29 infos preexistentes, ninguno de
  T061.
- `dart format lib/data/learning test/data/learning`: limpio.
- `git diff --check`: limpio.
- Rust T062: `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings` y
  `cargo test --all-targets` limpios tras T063; 33 tests pasan y el unico ignored
  es el gate oficial que requiere el corpus ausente. Release build limpio.
- Flutter vigente: 173 passed, 1 skip y analyze exit 0; el reintento tras T063
  fue reemplazado por los gates T064: 182 passed, 1 skip y analyze exit 0 con 29
  infos preexistentes. El proceso Dart huérfano PID 28632 se cerro con aprobacion
  del propietario para desbloquear el toolchain.

## Como continuar

1. Leer `AGENTS.md` y este handoff.
2. Aplicar, en orden, `$project-clean-architecture`, `$spec-task-executor` y
   `$guitar-learning-mode`.
3. Iniciar T066 e implementar el clock de practica monotonico; escribir sus
   tests sin ejecutar gates y entregar los comandos al propietario.
4. Mantener T022 y T062 en la lista de pendientes externos para recuperarlos en
   la auditoria final antes de declarar validacion real completa.

## Limites del siguiente bloque

- T062 no implementa FFI, Dart, UI, scoring ni clasificacion libre de acordes.
- Preservar sin cambios el ABI y los resultados del afinador monofonico.
- Aplicar `$guitar-learning-mode` con la ruta DSP/chords y ejecutar `cargo test`.
- No generar tonos sinteticos y presentarlos como corpus real; el aplazamiento
  de T062 no equivale a cerrar sus gates.
- No iniciar E09 ni tareas dependientes antes de cerrar T072.
