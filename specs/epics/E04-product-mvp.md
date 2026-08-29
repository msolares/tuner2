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

## Reglas de interacción de presets
- El preset activo debe ser visible y seleccionable sin desplazarse hasta los ajustes avanzados.
- La insignia superior que muestra el preset activo es el acceso principal al selector.
- Al pulsar la insignia se muestran todos los perfiles de `kMvpInstrumentPresets`, con el preset actual identificado visualmente.
- La selección reutiliza el flujo existente de `SelectPreset`; no modifica contratos de dominio, BLoC, motor de pitch ni FFI.
- Si existe una afinación obtenida por canción, una selección manual de preset limpia ese resultado y vuelve a mostrar el mapa de cuerdas del preset elegido.
- La calibración A4 permanece en el panel de configuración; el selector de preset no se duplica allí.

## Escenarios clave
- Nota estable sostenida.
- Cambios rápidos de nota.
- Ruido ambiente y baja confidence.
- Sonidos no instrumentales (`voz`, aire, ventilador) sin lock estable espurio.
- Cambios de A4 en caliente.

## Criterios de aceptación
- Flujo completo start/stop funcional.
- Parámetro A4 impacta cálculo en tiempo real.
- Mensajes de error claros en denegación de permisos o falla de engine.
- El afinador prioriza tonos instrumentales útiles y evita sostener lecturas confiables ante entrada no instrumental.
