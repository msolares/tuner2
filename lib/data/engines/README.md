# Estrategia de engines por plataforma (T006)

Objetivo:
- Mantener el mismo contrato de dominio `TunerEngine` en movil y Web.

Implementaciones previstas:
- Movil: engine Rust via FFI (Android/iOS).
- Web: implementacion Dart pura, sin FFI nativo.

Reglas:
- No se modifica la firma de `TunerEngine` por diferencias de plataforma.
- La capa `presentation` consume solo contrato de `domain`.
- La seleccion de engine por plataforma ocurre en `data`.
