# Gates de merge CI (T018)

## Jobs obligatorios

- `flutter-quality`
- `rust-quality`
- `specs-consistency`

## Reglas de merge

- No se permite merge con jobs en fallo.
- `flutter analyze` y `flutter test` deben pasar.
- `cargo fmt --check`, `cargo clippy`, `cargo test` deben pasar.
- Estructura minima de specs (`Estado` + `Evidencia`) debe validar.

## Archivos clave

- Pipeline: `.github/workflows/ci.yml`
- Plan pruebas Dart: `specs/quality/dart-test-plan.md`
- Plan pruebas Rust: `specs/quality/rust-test-plan.md`
- Integracion FFI: `specs/quality/ffi-integration-test-plan.md`
