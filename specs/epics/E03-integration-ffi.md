# E03 - Integracion FFI

## Objetivo
Cerrar el contrato técnico entre Flutter y Rust para la capa de audio y detección.

## API FFI definida
- `tuner_init(config_json_ptr) -> handle`
- `tuner_process_frame(handle, pcm_ptr, len, sample_rate) -> pitch_result`
- `tuner_update_config(handle, config_json_ptr) -> error_code`
- `tuner_dispose(handle) -> error_code`

## Mapeo de tipos
- Rust `f32` <-> Dart `double` (acotado por contrato).
- Resultado de pitch con campos: `hz`, `cents`, `note`, `confidence`.
- Configuración serializada en JSON para desacoplar versiones.

## Lifecycle
1. Inicializar handle.
2. Procesar frames en bucle.
3. Actualizar configuración en caliente.
4. Liberar handle al detener.

## Criterios de aceptación
- Manejo de errores propagado hasta UI.
- No hay leaks de handles en start/stop repetido.
- Contrato Web definido como implementación Dart paralela.
