# T053 - Cabecera consistente y localizacion ES/EN

## Estado
- done

## Prioridad
- P1

## Epic
- E01, E04, E07

## Dependencias
- T045, T046, T052

## Objetivo
Normalizar el tamaño visual de las insignias `READY`, preset y `% CONF`, e incorporar un gestor de idiomas que muestre automaticamente la interfaz en español o ingles según el idioma del navegador o dispositivo.

## Entradas
- `lib/main.dart`
- `lib/app/`
- `lib/presentation/screens/app_shell.dart`
- `lib/presentation/screens/tuner_screen.dart`
- `lib/presentation/screens/metronome_screen.dart`
- Mensajes visibles de los BLoC de afinador, metrónomo y afinación por canción.
- Tests de app y pantallas en `test/`.

## Alcance
- Igualar altura, alineación y área táctil de las tres insignias de la cabecera del afinador.
- Añadir localización tipada para español e inglés sin introducir estado de idioma en dominio ni BLoC.
- Resolver el idioma inicial desde el `Locale` de plataforma proporcionado por Flutter.
- Usar español para cualquier locale `es-*` e inglés para `en-*` y locales no soportados.
- Traducir navegación, afinador, metrónomo, diálogos, ayudas, tooltips, semántica y mensajes de error conocidos.
- Localizar los nombres visibles de presets sin cambiar sus identificadores ni perfiles técnicos.
- Mantener el comportamiento responsive actual en móvil y Web.

## Fuera de alcance
- Selector manual de idioma o persistencia de una preferencia propia.
- Nuevos idiomas además de español e inglés.
- Traducción de nombres propios, notas musicales, BPM, Hz o contenido devuelto por servicios externos.
- Cambios en detección, audio, ajustes de presets, BLoC, dominio, Web engine o Rust FFI.

## Decisiones
- `MaterialApp` declara `supportedLocales`, delegados Flutter y resolución explícita de locale.
- La localización por defecto para un idioma no soportado es inglés.
- Los errores mantienen sus códigos y mensajes internos actuales; presentación traduce los mensajes conocidos antes de mostrarlos.
- Las tres insignias superiores comparten una altura mínima de 48 dp y alineación vertical centrada.
- Los textos más largos deben envolver o reorganizarse sin overflow a 320 px.

## Criterios de aceptación
- Con locale `es-ES`, la navegación y pantallas visibles aparecen en español.
- Con locale `en-US`, aparecen en inglés.
- Con un locale no soportado, la interfaz usa inglés.
- Cambiar el locale de plataforma provoca que Flutter reconstruya la interfaz en el idioma correspondiente.
- `READY`, preset y `% CONF` tienen la misma altura visual en la cabecera.
- El selector de preset conserva sus cinco opciones, marca activa y comportamiento de `T052`.
- Afinador y metrónomo no presentan mezcla evitable de español e inglés.
- No hay overflow a 320 px en los casos cubiertos.
- Tests, análisis y build Web quedan validados.
- Se registra evidencia de cierre en esta task.

## Plan de implementacion
1. Crear `AppLocalizations`, locales soportados, resolución de plataforma y traducciones ES/EN.
2. Conectar delegados, locales y título localizado en `MaterialApp`.
3. Sustituir cadenas visibles en navegación, afinador y metrónomo por recursos localizados.
4. Traducir en presentación los mensajes de error conocidos sin modificar contratos BLoC.
5. Igualar geometría de las insignias superiores y añadir una aserción de widget test.
6. Agregar tests de resolución `es`, `en`, fallback y render localizado.
7. Ejecutar formato, análisis, suite Flutter, build Web y validación visual en ambos idiomas.

## Evidencia de cierre
- Gestor implementado en `lib/app/app_localizations.dart` con español, inglés, fallback a inglés, nombres de presets, semántica y traducción de errores conocidos.
- `MaterialApp` conectado en `lib/main.dart` con locales soportados, delegados Material/Widgets/Cupertino, título localizado y resolución desde navegador/dispositivo.
- Navegación, afinador y metrónomo migrados a recursos localizados en:
  - `lib/presentation/screens/app_shell.dart`
  - `lib/presentation/screens/tuner_screen.dart`
  - `lib/presentation/screens/metronome_screen.dart`
- Las insignias de estado, preset y confidence usan altura mínima común de 48 dp, centrado vertical y ancho ajustado al contenido.
- Tests nuevos en `test/app/app_localizations_test.dart` cubren `es-*`, fallback de locale no soportado e integración de `MyApp` con locale de plataforma.
- `test/presentation/screens/tuner_screen_test.dart` comprueba igualdad exacta de altura entre las tres insignias y conserva los casos de selector y 320 px.
- `test/presentation/screens/metronome_screen_test.dart` valida la interfaz española y el layout a 320 px.
- `flutter test --no-pub`: 102 tests en verde y 1 test histórico omitido por falta de harness multiplataforma.
- `flutter analyze --no-pub --no-fatal-infos`: sin errores ni warnings; permanecen 26 avisos informativos preexistentes.
- `flutter build web --no-pub`: build Web correcto y dry run Wasm superado.
- Validación manual Web con locale español:
  - Cabecera con `LISTO`, `GUITARRA (EADGBE)` y `0% CONF` alineados y con ancho ajustado al contenido.
  - Menú con `Cromático`, `Guitarra`, `Ukulele`, `Bajo` y `Violín`.
  - Afinador, navegación y metrónomo visibles en español sin errores de consola.
- La variante inglesa y el fallback se validan mediante widget tests deterministas de locale.
