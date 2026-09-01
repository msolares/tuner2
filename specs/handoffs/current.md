# Handoff actual

## Punto de reanudacion

- Rama: `aprendizaje-musical`.
- Ultimo bloque cerrado: T069 - pantalla responsive del modo educativo (`done`,
  validacion incremental diferida por decision del propietario).
- T062 permanece `in_progress` por el corpus PCM real aplazado por autorizacion
  explicita del propietario para probar primero la app sin musica.
- T022 permanece `todo` por validacion fisica Android/iOS aplazada de forma
  explicita; no invalida el cierre tecnico de T064.
- Siguiente task: T070 - integracion de cuenta, espera, reentrada y velocidad.
- Estado esperado del worktree al reanudar: cambios acumulados de T058..T068 sin
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
- Completado el contrato del clock con el `tempoMap` del chart e implementado un
  scheduler Dart monotónico comun para movil/Web, basado en objetivos absolutos,
  junto con un fake determinista reutilizable.
- Implementado `LessonBloc` con eventos serializados, estado UI derivado de
  `LessonSessionState`, delegacion completa a casos de uso y cancelacion de
  clock/analyzer en stop, errores, lifecycle, recarga y dispose.
- Implementado el mapper/render model acotado a 40 bloques y el painter de mastil
  con seis cuerdas, perspectiva, estados, `RepaintBoundary`, semantica y fallback
  vertical. Los cuatro goldens estan definidos pero sus PNG/revision quedan
  pendientes de la ejecucion manual diferida.
- Implementada la pantalla educativa horizontal responsive con jerarquia
  completa, controles, progreso/compas/velocidad/microfono, estados textuales,
  diagrama de acorde y evidencia cromatica cruda. La pantalla localiza ES/EN,
  respeta reduce motion, sustituye gameplay en vertical y solicita stop antes
  de salir o disponer recursos.
- `LessonBlocState` conserva solo la observacion cruda valida del target actual
  para feedback visual, sin trasladar umbrales ni decisiones pedagogicas a
  Presentation; se limpia al reiniciar, detener, repetir, cambiar target o
  fallar.
- Escritos tests T069 para arquitectura, BLoC/evidencia, estados, controles,
  ES/EN, lifecycle, tamaños normativos y tres goldens; no se ejecutaron ni se
  generaron PNG por la politica de validacion diferida.
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
3. Iniciar T070 e integrar extremo a extremo cuenta visual, espera, acierto,
   reentrada, velocidad, repeticion/final y telemetria local en memoria; escribir
   sus tests sin ejecutar gates y entregar los comandos al propietario.
4. Mantener T022 y T062 en la lista de pendientes externos para recuperarlos en
   la auditoria final antes de declarar validacion real completa.

## Limites del siguiente bloque

- T070 integra contratos ya implementados; no introduce audio real, persistencia
  remota ni scoring competitivo.
- La cuenta E08 es exclusivamente visual y el clock musical sigue siendo la
  autoridad temporal.
- La telemetria de intentos/precision queda solo en memoria y no inventa
  progreso de usuario.
- No iniciar E09 ni tareas dependientes antes de cerrar T072.
