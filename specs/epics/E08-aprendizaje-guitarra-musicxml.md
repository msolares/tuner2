# E08 - Aprendizaje de guitarra con MusicXML

## Objetivo

Incorporar un modo educativo horizontal con mastil virtual que cargue ejercicios MusicXML, guie notas y acordes, escuche al alumno y detenga la linea temporal hasta reconocer correctamente cada objetivo. Debe preservar sin cambios los afinadores existentes y preparar una base reutilizable para canciones con audio y futuros minijuegos.

## Decisiones cerradas

- Flutter continua siendo el shell y renderer.
- `CustomPainter` renderiza el mastil; Unity y Flame quedan fuera de E08.
- El motor movil usa Rust FFI y Web implementa el mismo contrato en Dart.
- `TunerEngine` no cambia; se introduce `PerformanceAnalyzer`.
- MusicXML se transforma una vez a `LessonChart`; presentation nunca consume XML.
- El reloj musical usa 960 ticks por negra.
- E08 no reproduce audio: la cuenta inicial y la reentrada son visuales. Toda reproduccion pertenece a E09.
- La velocidad se controla entre 50% y 100% sin cambiar pitch.
- La posicion de cuerda/traste es recomendada; el microfono valida sonido.
- Los acordes se reconocen de forma dirigida contra el target conocido.
- E08 soporta notas, power chords y triadas mayores/menores.
- La sesion se detiene siempre en cada objetivo requerido.
- Tras un acierto ejecuta feedback de 250 ms y reentrada de un pulso.
- El shell incorpora un tercer destino inferior `Clases`; su catalogo inicial es local y todas las clases estan disponibles.
- Juegos, scoring competitivo y audio comercial quedan fuera.

## Arquitectura

Aplican sin excepcion:

- `specs/architecture/clean-architecture.md`.
- `specs/learning/domain-contracts.md`.
- `specs/learning/use-cases.md`.
- `specs/learning/musicxml-profile.md`.
- `specs/design/learning-fretboard.md`.
- `specs/design/classes-path.md`.

### Domain

- Entidades del chart, targets, observaciones y sesion.
- Puertos `LessonCatalog`, `LessonChartDecoder`, `PerformanceAnalyzer` y `LessonClock`.
- Politica de evaluacion y maquina de estados determinista.
- Casos de uso UC-L00..UC-L10.

### Data

- Catalogo de assets/documentos.
- Decoder MusicXML seguro y normalizador a 960 PPQ.
- Clock monotónico.
- Analyzer movil Rust/FFI para notas y acordes.
- Analyzer Web equivalente en Dart.
- Traduccion de errores tecnicos a errores de dominio.

### Presentation

- `LessonBloc` consume casos de uso.
- `FretboardRenderModel` inmutable.
- `CustomPainter` sin reglas musicales.
- Pantalla horizontal responsive, controles y accesibilidad.

### Composition root

- Construye implementaciones por plataforma.
- Coordina exclusividad de microfono entre afinador y leccion.
- Detiene el modo saliente antes de iniciar el entrante.

## Flujo funcional principal

1. Usuario elige una leccion.
2. UC-L01 carga y valida MusicXML.
3. UC-L02 prepara seccion y velocidad.
4. UC-L03 obtiene permiso e inicia analyzer/clock.
5. Cuenta atras visual de un compas; el clock recorre ticks previos con evaluacion desactivada.
6. El mastil avanza por ticks.
7. Al llegar a una nota o acorde obligatorio se congela.
8. UC-L05 valida evidencia nueva.
9. Si falla, muestra feedback y sigue escuchando.
10. Si acierta, registra resultado y ejecuta reentrada de un pulso.
11. Continua hasta terminar la seccion.
12. UC-L09 libera todos los recursos.

## Deteccion de acordes

### Contrato de producto

- El target proviene del MusicXML y es conocido antes del analisis.
- Un acorde se valida por clases tonales requeridas, no por clasificacion libre.
- Duplicados de una clase tonal no se exigen por separado.
- No se afirma que una cuerda concreta sono o fallo.
- El alumno ve la digitacion exacta recomendada.

### DSP movil

- Front-end espectral independiente del detector monofónico.
- Ventana de acumulacion orientada a rasgueos de hasta 700 ms.
- Extraccion de evidencia cromatica normalizada C..B.
- Supresion/control de armonicos para no confundir parciales con tonos requeridos.
- Ataque nuevo mediante `onsetSequence`.
- Sin allocations sin limite por frame y sin bloquear el hilo UI.

### Web

- Mismo significado de los 12 valores y mismos rangos.
- Tests de conformidad con los mismos fixtures PCM.
- Diferencia de exactitud maxima permitida: 5 puntos porcentuales frente a movil en el corpus oficial.

## Contenido inicial

La primera clase es un fixture propio y pequeño: pentatonica menor de La, primera posicion, ascendente y descendente, nota a nota y sin audio. Sirve para validar el recorrido completo antes de ampliar el catalogo a acordes y canciones.

`prueba-tablatura.xml` se usa como compatibilidad de importacion compleja, no como primera leccion de usuario.

## Navegacion y lifecycle

- La nueva pantalla no altera las ramas ni contratos de los afinadores.
- La barra inferior contiene exactamente `Afinador`, `Metronomo` y `Clases` en E08.
- `Clases` abre una ruta vertical de nodos seleccionables; al elegir uno se muestra su ficha y se entra al mastil.
- No se muestran candados, rachas, estrellas ni progreso ficticio hasta definir el contrato de API en una fase posterior.
- Solo un modo posee el microfono.
- Background, cambio de modo, dispose o error ejecutan parada idempotente.
- Volver a foreground deja la sesion `ready`; nunca reanuda microfono sin accion del usuario.
- No se permite analyzer duplicado ni suscripcion residual.

## Calidad

- Tests de dominio para todas las transiciones y casos limite.
- Tests del importer con fixtures minimos y el XML real.
- Corpus DSP sintético y grabado para notas/acordes.
- Tests de conformidad movil/Web.
- Widget/golden tests del mastil y estados.
- Integracion con microfono real documentada en Android, iOS y Web.
- Presupuestos de `specs/quality/learning-mode-test-plan.md` cumplidos.

## Fuera de alcance

- Audio real sincronizado y time-stretch: E09.
- Reconocimiento libre de cualquier acorde.
- Acordes extendidos, inversiones exigidas o deteccion exacta por cuerda.
- Evaluacion de bends, slides, hammer-ons, vibrato y dinamica.
- Afinaciones de mas o menos de seis cuerdas.
- Juegos Flame/Unity, perfiles online, monetizacion o catalogo remoto.
- Persistencia de avance, desbloqueos, login y API de clases.
- Importar Guitar Pro binario.

## Criterios de aceptacion

- Una leccion valida se carga desde MusicXML sin filtrar tipos XML fuera de data.
- El destino Clases lista el catalogo local en orden y abre la primera ficha sin solicitar microfono.
- Notas y acordes aparecen en cuerda, traste y tick correctos.
- El mastil se congela exactamente en cada target requerido.
- Ruido, resonancia anterior y observaciones antiguas no desbloquean.
- Una nota correcta y un acorde soportado reanudan mediante la politica educativa.
- Velocidad cambia entre 50% y 100% manteniendo tick y pitch.
- La UI mantiene 60 FPS dentro del presupuesto definido.
- Movil y Web cumplen el mismo contrato y corpus.
- Afinador y metronomo conservan sus APIs y pruebas.
- Start/stop y lifecycle no dejan streams, clocks o handles activos.

## Riesgos y mitigaciones

- **Falsos acordes por armonicos:** target dirigido, evidencia cromatica y corpus de negativos.
- **Misma nota en posiciones distintas:** UI declara digitacion recomendada; evaluacion tonal.
- **XML variable:** perfil cerrado, errores tipados y normalizacion segura.
- **Deriva visual:** clock musical monotónico; painter no gobierna tiempo.
- **Carga de UI por DSP:** Rust/adapter fuera de UI y observaciones compactas.
- **Crecimiento sin control:** una task/feature y contratos actualizados antes de ampliar alcance.
