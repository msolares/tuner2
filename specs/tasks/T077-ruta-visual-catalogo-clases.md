# T077 - Ruta visual y seleccion de clases

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057, T061

## Objetivo
Implementar la pantalla vertical de clases y la seleccion de una leccion local sin progreso ni API.

## Entradas
- `specs/design/classes-path.md`
- `specs/learning/domain-contracts.md`
- `specs/learning/use-cases.md`

## Alcance
- BLoC de catalogo que consume UC-L00.
- Estados loading/content/empty/failure.
- Camino vertical de nodos seleccionables y ficha de clase.
- Navegacion desde la ficha hacia la pantalla educativa mediante `LessonId`.
- Accesibilidad, localizacion ES/EN y tests visuales.

## Fuera de alcance
- Barra inferior del shell, microfono, parseo XML, progreso, bloqueos, usuario, red o API.

## Criterios de aceptación
- Presentation no importa data ni conoce rutas de assets.
- Los nodos respetan el orden de UC-L00 y todos son seleccionables.
- La primera clase muestra pentatonica menor de La, primera posicion y 3 minutos.
- Abrir la ruta no solicita permiso de microfono.
- Estados, scroll, accesibilidad y vuelta desde la ficha tienen widget tests.
- Golden tests no presentan overflow en los tamaños definidos por el plan de calidad.

## Evidencia de cierre
- Pendiente.
