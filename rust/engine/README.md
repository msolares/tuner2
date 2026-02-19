# Engine Rust - Diseno modular (T004)

Objetivo:
- Separar responsabilidades internas del motor en modulos con una sola responsabilidad.

Mapa de modulos:
- `input`: normalizacion y validacion de frames PCM.
- `detector`: estimacion de frecuencia fundamental.
- `smoothing`: estabilizacion temporal y calculo de confidence.
- `ffi`: borde publico para integracion con Flutter via C ABI.

Flujo interno:
1. `ffi` recibe frame y contexto.
2. `input` valida formato y sample rate.
3. `detector` calcula frecuencia base.
4. `smoothing` estabiliza salida y confidence.
5. `ffi` serializa resultado y codigos de error.

Reglas internas:
- `detector` no conoce detalles de FFI.
- `smoothing` no accede a punteros ni handles FFI.
- `ffi` no contiene logica DSP; solo orquestacion, errores y lifecycle.

Notas de alcance:
- Este diseno define limites modulares (T004).
- Las firmas C ABI y codigos de error explicitos se cierran en `T005`.
