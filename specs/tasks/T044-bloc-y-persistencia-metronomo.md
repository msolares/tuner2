# T044 - BLoC y persistencia del metrónomo

## Estado
- done

## Prioridad
- P0

## Epic
- E07

## Dependencias
- T041

## Objetivo
Implementar el estado de aplicación del metrónomo, sus actualizaciones en caliente, `tap tempo` y recuperación de configuración.

## Entradas
- Contratos de T041.
- Patrones existentes en `lib/presentation/bloc/` y `lib/data/settings/`.

## Alcance
- Implementar eventos y estado definidos en E07.
- Implementar `MetronomeBloc` con dependencias de dominio.
- Calcular `tap tempo` con ventana móvil, rechazo de intervalos inválidos y clamp de BPM.
- Persistir únicamente configuraciones válidas y versionadas.
- Restaurar defaults ante ausencia o corrupción.
- Tratar errores de engine como recuperables.

## Fuera de alcance
- Widgets, navegación y audio concreto.

## Entregables
- BLoC, adaptador `SharedPreferences` y tests unitarios/BLoC.

## Criterios de aceptación
- Cada evento produce una transición determinista.
- Los cambios durante reproducción llaman a `update`, no reinician el engine.
- La configuración se restaura tras recrear el BLoC.
- Los ticks obsoletos no actualizan estado tras stop.
- Los errores permiten volver a iniciar.

## Riesgos
- Escrituras excesivas de preferencias durante cambios rápidos de controles.

## Evidencia de cierre
- `MetronomeBloc`, eventos y estado implementados en `lib/presentation/bloc/`.
- Persistencia versionada mediante `SharedPreferencesMetronomeSettingsStore`.
- Tap tempo con ventana móvil y mediana de intervalos.
- 4 tests BLoC en verde, incluidos lifecycle de ticks y stop.
