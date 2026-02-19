# E02 - Rust Engine

## Objetivo
Definir el motor de detección de pitch en Rust para móvil con foco en estabilidad, precisión y performance.

## Módulos del engine
- `input`: normalización y validación de frames PCM.
- `detector`: cálculo de frecuencia fundamental.
- `smoothing`: estabilización temporal y confidence.
- `ffi`: C ABI para consumo desde Flutter.

## Requisitos no funcionales
- Sin panics en ruta pública FFI.
- Liberación segura de memoria y handles.
- Latencia objetivo apta para visualización en tiempo real.

## Errores esperados
- Handle inválido.
- Frame inválido o sample rate no soportado.
- Error interno del detector.

## Criterios de aceptación
- API FFI definida con códigos de error explícitos.
- Estrategia de tests unitarios y de robustez documentada.
