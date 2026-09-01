# E09 - Audio real, velocidad y sincronizacion de canciones

## Estado

- Planificado despues de completar E08.
- Sus contratos se cierran aqui para evitar que E08 adopte decisiones incompatibles.

## Objetivo

Permitir que un `LessonChart` se interprete sobre una grabacion real a velocidad educativa, manteniendo afinacion, sincronizacion, pausa por objetivo y reentrada.

## Contratos adicionales

```dart
final class BackingTrack {
  final String id;
  final int durationMs;
}

final class BeatMapPoint {
  final int chartTick;
  final int audioPositionMs;
}

final class SynchronizedLessonMedia {
  final BackingTrack track;
  final List<BeatMapPoint> beatMap;
}

final class PlaybackPosition {
  final int audioPositionMs;
  final int monotonicTimestampMs;
  final bool playing;
}

abstract interface class LessonPlaybackEngine {
  Future<void> load(SynchronizedLessonMedia media);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(int audioPositionMs);
  Future<void> setSpeed(double speed);
  Stream<PlaybackPosition> positions();
  Future<void> stop();
}
```

`BackingTrack.id` es una referencia logica. Solo el adaptador data resuelve assets, archivos o URLs; dominio no conoce rutas ni proveedores.

## Invariantes

- Velocidad `0.50..1.00` en pasos de 0.05.
- Time-stretch conserva pitch; cambiar velocidad no cambia las notas esperadas.
- El audio es el reloj maestro. El chart tick se interpola desde `beatMap`.
- Beat map ordenado, comienza antes o en el primer evento y termina despues o en el ultimo.
- Los repeats ya estan expandidos en el chart y el beat map lineal.
- Una pausa detiene audio y posicion visual atomicamente.
- La captura de microfono continua durante espera; la reproduccion queda pausada.
- Auriculares son recomendados y pueden ser requisito de contenido.
- Una mezcla completa no puede validar el target por audio reproducido: se exige auriculares o backing sin guitarra.

## Reentrada con audio

1. Fade-out de 50 ms al entrar en espera.
2. Tras acierto, convertir `event.startTick - reentryTicks` a audio mediante beat map.
3. Seek al punto de reentrada.
4. Reproducir el pulso previo con evaluacion desactivada.
5. Al cruzar el target ya acertado, continuar y activar el siguiente objetivo.

## Fuera de alcance inicial

- Streaming protegido/DRM.
- Separacion de stems en dispositivo.
- Cambio de tonalidad.
- Velocidad inferior a 50%.
- Alineacion automatica perfecta de cualquier grabacion.
- Licenciamiento y distribucion de catalogos comerciales.

## Criterios de aceptacion

- La grabacion y el mastil permanecen dentro de 40 ms p95 en los dispositivos de referencia.
- El pitch no cambia mas de 5 cents al variar velocidad.
- Pause/seek/reentry no producen doble audio ni targets duplicados.
- Android, iOS y Web respetan el contrato, documentando diferencias de calidad.
- E08 funciona sin audio y no depende de `LessonPlaybackEngine`.
