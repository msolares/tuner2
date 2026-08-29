# T045 - App shell y navegación inferior

## Estado
- done

## Prioridad
- P0

## Epic
- E07, E01

## Dependencias
- T041, T044

## Objetivo
Convertir la navegación inferior decorativa actual en un `AppShell` funcional con destinos Afinador y Metrónomo, preservando el afinador existente.

## Entradas
- `lib/main.dart`
- `lib/presentation/screens/tuner_screen.dart`
- `lib/app/platform_dependencies*.dart`

## Alcance
- Extraer la navegación global fuera de `TunerScreen`.
- Crear `AppShell` con `IndexedStack` y dos destinos accesibles.
- Mantener Afinador como destino inicial.
- Proveer ambos BLoC desde composition root.
- Detener de forma ordenada el modo saliente y al entrar en background.
- Conservar en memoria la configuración de ambas pantallas.

## Fuera de alcance
- Rediseñar o cambiar la lógica funcional interna del afinador.
- Reproducción simultánea de ambos modos.

## Entregables
- Shell, navegación y pruebas de integración de ciclo de vida.

## Criterios de aceptación
- Ambas pestañas son navegables por toque y semántica.
- La UI y los flujos existentes del afinador siguen pasando sus tests.
- Cambiar de pestaña detiene el modo saliente una sola vez.
- Volver a una pestaña no recrea configuraciones ni suscripciones.
- Background libera micrófono y salida de audio.

## Riesgos
- Mover el `Scaffold` puede alterar accidentalmente FAB, safe areas o navegación del afinador.

## Evidencia de cierre
- `AppShell` implementado con `IndexedStack` y navegación Afinador/Metrónomo.
- El afinador conserva pantalla, BLoC y acción principal; únicamente se extrajo su navegación decorativa.
- Cambio de pestaña y background envían stop al modo saliente.
- Widget test del shell y navegación en verde.
