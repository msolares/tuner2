# T054 - Simplificar cabecera del afinador

## Estado
- done

## Prioridad
- P1

## Epic
- E04

## Dependencias
- T052, T053

## Objetivo
Reducir el ruido visual de la cabecera dejando únicamente el selector del tipo de afinador y retirando las insignias duplicadas de estado y confidence.

## Alcance
- Eliminar de la cabecera las insignias `READY/LISTO` y `% CONF`.
- Mantener el selector de preset en la misma zona, con idioma, semántica y comportamiento existentes.
- Mantener el estado `READY/LISTO`, `IN TUNE/AFINADO`, etc. dentro del medidor central.
- Mantener intactos los datos de confidence y su uso interno en detección.
- Actualizar documentación y widget tests afectados.

## Fuera de alcance
- Cambios en BLoC, dominio, motor de pitch, audio, presets o FFI.
- Eliminar estados del medidor central.
- Cambiar la lógica de confidence.

## Criterios de aceptación
- La cabecera solo muestra una insignia interactiva: el selector de preset.
- No aparecen `READY/LISTO` ni `% CONF` en la cabecera.
- El medidor central sigue mostrando el estado actual.
- El selector mantiene sus cinco opciones y funciona en español e inglés.
- No hay overflow a 320 px.
- Tests y build Web quedan en verde.

## Plan de implementacion
1. Retirar las dos insignias y los parámetros de presentación innecesarios.
2. Eliminar el widget privado sin usos y conservar el selector.
3. Adaptar pruebas de cabecera y responsive.
4. Ejecutar tests, build Web y validación visual.

## Evidencia de cierre
- Cabecera simplificada en `lib/presentation/screens/tuner_screen.dart`: se eliminaron las insignias de estado y confidence, sus parámetros de presentación y el widget privado sin usos.
- El selector de preset permanece como única insignia interactiva de la cabecera, con localización ES/EN y cinco opciones intactas.
- El estado sigue visible dentro del medidor central y la lógica interna de confidence no se modificó.
- `test/presentation/screens/tuner_screen_test.dart` valida la ausencia de ambas insignias, el selector, el menú y el layout a 320 px.
- `flutter test --no-pub`: 102 tests en verde y 1 test histórico omitido.
- `flutter build web --no-pub`: build Web correcto y dry run Wasm superado.
- Validación visual Web en español: cabecera con una sola insignia `GUITARRA (EADGBE)`, medidor central con `LISTO` y consola sin errores.
