# T069 - Pantalla responsive del modo educativo

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T061, T067, T068

## Objetivo
Implementar la pantalla horizontal completa con mastil, estado de espera, diagrama de acorde, progreso y controles.

## Entradas
- `specs/design/learning-fretboard.md`
- `lib/app/app_theme.dart`

## Alcance
- Layout movil/tablet/Web.
- Paneles, progreso, compas, velocidad y microfono.
- Estados running/waiting/validating/success/reentry/failure.
- Diagrama de acorde y feedback por clase tonal.
- Accesibilidad, localizacion ES/EN y reduce motion.

## Fuera de alcance
- Nueva identidad visual, audio real o minijuegos.

## Criterios de aceptación
- Jerarquia coincide con la referencia aprobada.
- Sin overflow en tamaños normativos.
- Estado no depende solo de color.
- Cerrar pantalla solicita stop antes de dispose.
- Widget/golden tests en verde.

## Evidencia de cierre
- Pendiente.
