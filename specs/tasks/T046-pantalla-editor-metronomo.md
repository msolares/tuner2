# T046 - Pantalla y editor rítmico del metrónomo

## Estado
- done

## Prioridad
- P0

## Epic
- E07

## Dependencias
- T044, T045

## Objetivo
Construir la pantalla de metrónomo y el editor por tiempo con la identidad visual existente y comportamiento responsive.

## Entradas
- `lib/app/we_band_theme.dart`
- `specs/epics/E07-metronomo.md`
- `lib/presentation/`

## Alcance
- Cabecera, BPM, incremento/decremento, slider y `tap tempo`.
- Selector de presets y editor de compás personalizado.
- Secuencia de tiempos numerados con pulso/subdivisión activa.
- Selección de tónica, estado normal/silencio y subdivisión por cada tiempo.
- FAB o acción primaria start/stop coherente con el afinador.
- Estados idle, playing y error.
- Diseño responsive, scroll seguro y semántica accesible.

## Fuera de alcance
- Nuevas bibliotecas de sonidos o notación musical completa.

## Entregables
- `MetronomeScreen`, widgets reutilizables y widget tests.

## Criterios de aceptación
- El usuario completa todos los flujos de E07 sin diálogo técnico.
- La tónica y figura de cada tiempo son identificables sin depender solo del color.
- No hay overflow entre 320 px de ancho y layouts tablet/Web.
- El highlight visual sigue el tick y no gobierna el audio.
- Los cambios se reflejan en el BLoC y sobreviven a la navegación.

## Riesgos
- Exceso de controles visibles en compases con muchos tiempos.

## Evidencia de cierre
- Pantalla completa implementada en `lib/presentation/screens/metronome_screen.dart`.
- Incluye BPM, slider, tap tempo, presets, compás personalizado, editor por tiempo, tónica, silencio y subdivisiones.
- Los nombres de figura se calculan respecto al denominador: blanca, negra, corchea, semicorchea, fusa o semifusa según corresponda.
- Semántica por tiempo y estados visuales independientes del color.
- Test interactivo a 320 px en verde; se corrigieron overflows de BPM, compás y figuras.
