# T052 - Selector de preset en insignia superior

## Estado
- done

## Prioridad
- P1

## Epic
- E04

## Dependencias
- T012, T027, T035

## Objetivo
Hacer accesible el cambio entre `Guitar`, `Chromatic` y el resto de presets desde la insignia superior que muestra la afinacion activa, sin obligar a desplazarse y abrir el panel inferior de configuracion.

## Entradas
- `specs/epics/E04-product-mvp.md`
- `lib/presentation/screens/tuner_screen.dart`
- `lib/presentation/screens/README.md`
- `lib/domain/entities/instrument_preset_profile.dart`
- `test/presentation/screens/tuner_screen_test.dart`
- Eventos existentes `SelectPreset` y `SongTuningResultCleared`

## Alcance
- Convertir la insignia de preset de `_Header` en un control pulsable, conservando su posicion y jerarquia visual.
- Añadir un icono de despliegue y un area tactil accesible para comunicar que la insignia es interactiva.
- Mostrar, mediante un menu anclado a la insignia, todos los elementos de `kMvpInstrumentPresets` con sus `displayName` actuales.
- Identificar en el menu el preset actualmente activo mediante una marca visual que no dependa solo del color.
- Al elegir una opcion, emitir `SelectPreset` y `SongTuningResultCleared`, igual que hace el selector actual.
- Retirar el `DropdownButtonFormField` de preset del panel `TUNER SETUP`; mantener en ese panel la calibracion A4 y su informacion tecnica actual.
- Mantener el texto informativo del preset en el bloque `STRING MAP` sincronizado con el estado seleccionado.

## Fuera de alcance
- Cambios en deteccion de pitch, captura de audio, rangos, `noiseGateDb`, `smoothing` o comportamiento de los presets.
- Cambios en contratos de dominio, eventos/estados BLoC, `TunerEngine`, Web o Rust FFI.
- Crear, eliminar, renombrar o reordenar presets.
- Rediseñar el resto de la cabecera, el mapa de cuerdas o el panel de calibracion A4.
- Cambiar el flujo de afinacion por cancion más alla de limpiar su resultado al realizar una seleccion manual.

## Decisiones de interaccion
- Punto de entrada: la insignia superior cuyo texto es el `displayName` del preset activo en mayusculas.
- Componente: menu emergente anclado a la propia insignia, valido con toque, raton y teclado.
- Contenido: una opcion por elemento de `kMvpInstrumentPresets`; la opcion activa aparece marcada.
- Cierre: el menu se cierra al seleccionar una opcion, al pulsar fuera o al usar la accion de escape/volver de la plataforma.
- Feedback: la insignia y el texto de `STRING MAP` se actualizan desde el nuevo estado de `TunerBloc`, sin estado visual paralelo.
- Accesibilidad: etiqueta semantica que incluya el preset activo y la accion de cambiarlo, foco visible y objetivo tactil minimo de 48 x 48 dp.
- Responsive: el menu debe quedar dentro del viewport en movil y Web, incluso cuando la cabecera reorganice sus insignias mediante `Wrap`.

## Entregables
- Selector de presets accesible desde la cabecera del afinador.
- Panel inferior simplificado, sin selector duplicado.
- Widget tests de apertura, listado, seleccion, sincronizacion y accesibilidad basica.
- Documentacion de pantalla actualizada y evidencia de cierre registrada en esta task.

## Criterios de aceptacion
- El usuario puede pasar de `Guitar (EADGBE)` a `Chromatic` desde la zona visible inicial, sin hacer scroll ni abrir `TUNER SETUP`.
- Al pulsar la insignia aparecen los cinco perfiles actuales: `Chromatic`, `Guitar (EADGBE)`, `Ukulele (GCEA)`, `Bass (EADG)` y `Violin (GDAE)`.
- El preset activo se distingue en el menu sin depender exclusivamente del color.
- Elegir `Chromatic` desde `Guitar (EADGBE)` actualiza `TunerState.settings.instrumentPreset`, la insignia y el mapa de cuerdas correspondiente.
- Una seleccion manual limpia un resultado de afinacion por cancion visible, preservando el comportamiento actual.
- El panel `TUNER SETUP` conserva el ajuste A4 y ya no contiene un selector de preset.
- No cambian contratos ni archivos de `domain`, `data`, Rust o FFI, salvo los tests que consuman contratos ya existentes.
- No hay overflow a 320 px de ancho y el control funciona mediante toque, raton y teclado.
- `flutter analyze` y `flutter test test/presentation/screens/tuner_screen_test.dart` quedan en verde.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Una insignia sin indicador de despliegue puede seguir pareciendo solo informativa.
- Un menu ancho puede desbordar en pantallas pequeñas por los nombres completos de presets.
- Duplicar temporalmente el selector superior e inferior puede producir caminos de interaccion inconsistentes.
- El cambio manual debe seguir limpiando la afinacion por cancion para que el encabezado y el mapa de cuerdas no discrepen.

## Plan de implementacion
1. Extraer la insignia de preset de `_HeaderChip` a un widget interactivo dedicado que reciba preset activo y callback de seleccion.
2. Implementar el menu anclado usando `kMvpInstrumentPresets`, con icono de despliegue, marca de seleccion, semantica y navegacion por teclado.
3. Conectar la seleccion a los eventos existentes `SelectPreset` y `SongTuningResultCleared`, sin introducir estado local de preset.
4. Eliminar el selector duplicado de `_SettingsPanel` y ajustar sus textos para que describan solo la calibracion A4 y los valores tecnicos que permanecen.
5. Ampliar `tuner_screen_test.dart` para comprobar apertura sin scroll, cinco opciones, cambio Guitar -> Chromatic, limpieza de song tuning, ausencia del selector inferior y layout a 320 px.
6. Ejecutar formato, `flutter analyze` y el widget test afectado; registrar resultados y capturas movil/Web en `## Evidencia de cierre`.

## Evidencia de cierre
- Implementacion visual completada en `lib/presentation/screens/tuner_screen.dart`:
  - La insignia superior muestra un chevron y abre un menu anclado con los cinco presets actuales.
  - El preset activo se identifica mediante icono de check y peso tipografico, sin depender solo del color.
  - La seleccion reutiliza `SelectPreset` y `SongTuningResultCleared`.
  - El selector inferior fue eliminado y `TUNER SETUP` queda dedicado a `Calibration` A4.
  - La cabecera y `STRING MAP` se reorganizan en ancho estrecho para evitar overflow.
- Pruebas agregadas en `test/presentation/screens/tuner_screen_test.dart` para apertura sin scroll, catalogo completo, seleccion Guitar -> Chromatic, limpieza de afinacion por cancion, ausencia del selector inferior y ancho de 320 px.
- `flutter test test/presentation/screens/tuner_screen_test.dart --no-pub`: 5 tests en verde.
- `flutter test --no-pub`: 98 tests en verde y 1 test historico omitido por falta de harness multiplataforma.
- `flutter analyze --no-pub --no-fatal-infos`: sin errores ni warnings; permanecen 26 avisos informativos preexistentes fuera del alcance de T052.
- `flutter build web --no-pub`: build Web correcto y dry run Wasm superado.
- Validacion manual en navegador local:
  - Menu visible desde la insignia superior con `Chromatic`, `Guitar (EADGBE)`, `Ukulele (GCEA)`, `Bass (EADG)` y `Violin (GDAE)`.
  - Cambio real de `Guitar (EADGBE)` a `Chromatic` reflejado en la insignia y en `STRING MAP`.
  - Consola del navegador sin errores.
