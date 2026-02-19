# E04 - Product MVP

## Objetivo
Definir comportamiento funcional del afinador para el primer release útil.

## Funcionalidades MVP
- Escucha en tiempo real desde micrófono.
- Detección de nota/frecuencia.
- Desviación en cents e indicador `in tune`.
- Calibración de A4 por usuario.
- Presets básicos de instrumento.

## No funcionales
- UI reactiva y legible en móvil y web.
- Gestión de estado consistente para errores/permiso.

## Escenarios clave
- Nota estable sostenida.
- Cambios rápidos de nota.
- Ruido ambiente y baja confidence.
- Cambios de A4 en caliente.

## Criterios de aceptación
- Flujo completo start/stop funcional.
- Parámetro A4 impacta cálculo en tiempo real.
- Mensajes de error claros en denegación de permisos o falla de engine.
