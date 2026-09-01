# Plan de pruebas del modo educativo

## Objetivo

Validar E08 por capas, con resultados reproducibles antes de pruebas manuales.

## Dominio

- Construccion y rechazo de todas las invariantes de chart.
- Conversion exacta de ticks/tempo.
- Catalogo UC-L00 ordenado, vacio, invalido y con fallo tipado.
- Matriz completa de estados UC-L01..UC-L10.
- Nota correcta, cents limite, confidence limite y estabilidad.
- Observacion antigua, mismo ataque y dos notas iguales consecutivas.
- Acorde completo, incompleto, ataque debil y expiracion de ventana.
- Pausa, cambio de velocidad, repetir seccion, reentrada y stop idempotente.
- Clocks/analyzers fake: tests sin esperar tiempo real.

## MusicXML

Fixtures unitarios pequenos para cada construccion admitida y error tipado:

- Una nota, silencio y acorde.
- Dos voces y duplicacion standard/TAB.
- Cambios de divisions, tempo y compas.
- `backup`, `forward`, ties, grace y tuplets.
- Repeat simple y endings 1/2.
- Afinacion/capo/transposicion.
- Pitch y fret inconsistentes.
- DTD/entidad externa bloqueada.
- Limites de tamaño/nodos.
- Compatibilidad de `prueba-tablatura.xml`.
- Fixture `pentatonica-menor-la-posicion-1.musicxml`: 23 notas, 6 compases, 70 BPM y 23040 ticks.

## DSP monofónico

- Mantener corpus y escenarios existentes del afinador.
- Target conocido correcto/incorrecto por semitono y octava.
- Ataques repetidos de la misma nota.
- Ruido, voz, ventilador y silencio.
- Latencia p95 de observacion valida <= 180 ms tras ataque en dispositivo de referencia.

## DSP polifónico

Corpus versionado con PCM mono a 48 kHz:

- C, A, G, E, D mayores abiertos.
- Am, Em y Dm.
- Power chords en varias fundamentales.
- Positivos por al menos dos guitarras y tres intensidades.
- Negativos: acorde vecino, una nota requerida ausente, cuerda extra que sustituye
  un tono requerido o convierte el voicing en acorde vecino, nota aislada, ruido y
  voz. Una clase cromatica extra aislada no invalida por si sola un acorde E08.

Gates iniciales:

- Recall >= 90% en positivos limpios de microfono cercano.
- Falsa aceptacion <= 5% en negativos oficiales.
- Veredicto p95 <= 750 ms desde ataque.
- Paridad Web dentro de 5 puntos porcentuales de movil.
- Sin panic, NaN, infinito o crecimiento no acotado.

Los gates se miden sobre corpus, no se sustituyen por tonos sinteticos aislados.

## Presentation

- Barra inferior con Afinador, Metronomo y Clases.
- Ruta de clases vacia, con contenido y con error; seleccion y apertura de ficha.
- Widget tests de todos los estados.
- Golden tests en 640x360, 844x390, 1024x768 y 1440x900.
- Seis cuerdas visibles, acorde simultaneo alineado y trastes legibles.
- Semantica accesible y estados independientes del color.
- No overflow y orientacion horizontal.

## Rendimiento

- Chart sintetico de 1.000 eventos.
- <= 40 bloques enviados al painter por frame.
- 60 FPS; build+raster p95 <= 16,7 ms en referencia.
- Sesion de 10 minutos sin crecimiento sostenido de streams, handles o memoria.
- DSP no se ejecuta en isolate/hilo de UI.

## Integracion

- Permiso aceptado, denegado y concedido tras reintento.
- Cambiar afinador/leccion repetidamente.
- Background/foreground.
- Completar escala y progresion de acordes.
- Android, iOS y Web con microfono real.
- Evidencia incluye dispositivo/navegador, version, fixture, resultado y desviaciones.

## Gate de cierre E08

- `flutter analyze`.
- `flutter test`.
- `cargo test`.
- Tests de conformidad movil/Web.
- Evidencia manual de microfono real en las tres plataformas objetivo.
- Revision arquitectonica sin imports prohibidos.
