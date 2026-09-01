# T065 - PerformanceAnalyzer Web con paridad

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057, T062, T025, T039

## Objetivo
Implementar en Dart/Web el mismo contrato y semantica de evidencia monofonica/polifonica usando el corpus compartido.

## Entradas
- `specs/learning/domain-contracts.md`
- `specs/quality/learning-mode-test-plan.md`
- `lib/data/audio/web_*`

## Alcance
- Analisis dirigido nota/acorde.
- Strengths C..B, onset y confidence equivalentes.
- Uso del audio session Web existente.
- Control de CPU/buffer y errores tipados.
- Suite de conformidad compartida.

## Fuera de alcance
- Rust/Wasm, UI o reglas de acierto.

## Criterios de aceptación
- Diferencia de corpus <= 5 puntos porcentuales respecto a movil.
- No bloquea render ni crece el buffer.
- Start/stop y permisos siguen la politica Web existente.
- Mismo target produce observaciones semanticamente equivalentes.

## Evidencia de cierre
- Implementado `WebPerformanceAnalyzer` sobre el `AudioFrameSource` Web
  existente, con start/stop/setTarget idempotentes, captura unica, traduccion de
  permisos a `audioPermissionDenied` y liberacion tras errores.
- Implementado el kernel Dart dirigido para nota/acorde: detector monofonico
  existente, banco Goertzel MIDI 40..88, supresion de armonicos, 12 strengths
  C..B, ventana de rasgueo de 700 ms y onset global monotono equivalente al ABI
  movil.
- CPU y memoria quedan acotadas a 8192 muestras, 64 frames cromaticos y un unico
  frame pendiente. El banco espectral cede el event loop cada seis candidatos;
  stop espera al DSP en curso y descarta resultados tardios.
- Tests escritos para nota, acordes mayor/menor/power, rasgueo, onset, entrada
  invalida, presupuesto, backlog, lifecycle, permisos y errores. La suite
  existente del adaptador movil cubre las mismas formas semanticas de dominio.
- Validacion diferida por decision del propietario. Comandos para ejecutar:
  - `flutter test test/data/learning/performance`
  - `flutter analyze --no-fatal-infos`
  - `flutter build web`
  - `git diff --check`
- Resultado parcial previo al cambio de politica, registrado sin repetirlo: los
  20 tests de `test/data/learning/performance` pasaron antes del ultimo test de
  stop en vuelo; los 11 tests Web pasaron despues y el analyze dirigido quedo
  sin issues. El build Web fue interrumpido a peticion del propietario.
- La medicion oficial de diferencia <= 5 puntos porcentuales sigue aplazada
  junto al corpus PCM real de T062. No se sustituye por señales sinteticas; se
  verificara en el gate final y reabrira T065 si falla.
