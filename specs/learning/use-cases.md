# Casos de uso cerrados del modo educativo

## Alcance

Estos casos de uso son la unica entrada de presentation al comportamiento educativo de E08. Ningun BLoC reproduce estas reglas por su cuenta.

## UC-L00 - Listar clases

**Entrada:** ninguna.

**Dependencia:** `LessonCatalog`.

**Salida:** lista inmutable de `LessonSummary` ordenada por `sequenceIndex`.

**Reglas:**

1. Delegar la lectura al catalogo local sin conocer XML ni rutas.
2. Validar IDs e indices unicos, orden estrictamente ascendente por `sequenceIndex`, textos no vacios y duracion positiva.
3. En E08 todas las clases devueltas se pueden abrir; no inferir progreso, bloqueo o identidad de usuario.
4. Una lista vacia es valida y presentation muestra su estado vacio.
5. Un catalogo mal formado produce `invalidLessonCatalog`; un fallo de lectura produce `lessonCatalogUnavailable`. No devolver una lista parcial.

## UC-L01 - Cargar leccion

**Entrada:** `LessonId`, `LessonImportOptions`.

**Dependencias:** `LessonCatalog`, `LessonChartDecoder`.

**Salida:** `LessonChart` valido e inmutable.

**Reglas:**

1. Obtener el documento.
2. Decodificarlo al modelo canonico.
3. Validar todas las invariantes de `domain-contracts.md`.
4. No iniciar microfono, reloj ni UI.
5. Devolver error tipado; no devolver chart parcial.

## UC-L02 - Preparar sesion

**Entrada:** `LessonChart`, `sectionId?`, `speed`, `LessonEvaluationPolicy`.

**Salida:** estado `ready` en tick inicial de la seccion o 0.

**Reglas:** velocidad `0.50..1.00`; seccion existente; resultados vacios; primer objetivo requerido preseleccionado.

## UC-L03 - Iniciar sesion

**Precondicion:** estado `ready` o `completed` reiniciado.

**Efectos:** solicitar permiso, iniciar `PerformanceAnalyzer`, fijar primer target, iniciar `LessonClock` en `countIn`.

**Cuenta atras:** un compas completo segun el meter vigente en el tick inicial, calculado como `numerator * (4 / denominator) * 960` ticks. El clock comienza en `sectionStart - countInTicks`; los ticks negativos son validos solo como posicion transitoria de cuenta. Durante `countIn` no se evalua microfono y E08 no reproduce sonido. Al alcanzar `sectionStart` pasa a `running`.

## UC-L04 - Procesar tick musical

**Entrada:** `LessonClockTick`.

**Salida:** nuevo `LessonSessionState`.

**Reglas:**

- En `running`, actualizar posicion y objetivo visual.
- Al alcanzar `startTick` de un evento requerido pendiente, pausar el clock y entrar en `waitingForTarget`.
- En `waitingForTarget`, `validating`, `successFeedback`, `paused` o `failure`, un tick tardio no avanza la posicion.
- Los eventos opcionales no detienen el reloj.
- Al superar el final de seccion sin pendientes, pasar a `completed` y liberar analyzer/clock mediante UC-L09.

## UC-L05 - Procesar observacion

**Entrada:** `PerformanceObservation`.

**Precondicion:** `waitingForTarget` o `validating`.

**Nota individual:** aplicar MIDI, confidence, cents, estabilidad, timestamp y ataque nuevo segun la politica.

**Acorde:** abrir una ventana desde el primer ataque valido, acumular maximos por clase tonal y evaluar al cumplir condiciones o expirar la ventana. Si expira sin acierto vuelve a `waitingForTarget` con intento incrementado.

**Acierto:** registrar resultado, entrar en `successFeedback` durante 250 ms visuales y ejecutar UC-L06.

**Fallo:** mantener la sesion detenida; emitir feedback diagnostico sin marcar el evento como completado.

## UC-L06 - Ejecutar reentrada educativa

**Entrada:** evento recien acertado.

**Reglas E08 sin audio:**

1. Calcular `reentryStart = max(sectionStart, event.startTick - policy.reentryTicks)`.
2. Marcar el evento acertado para que no vuelva a bloquear.
3. Mover el clock a `reentryStart`.
4. Avanzar hasta el tick del evento con evaluacion desactivada y señal visual/sonora de cuenta.
5. En el tick del evento pasar a `running` y evaluar el siguiente evento.
6. Si el resultado es negativo, se admite como posicion transitoria de reentrada; los eventos del chart siguen siendo no negativos.

E09 sustituye el clock por la posicion del audio, pero conserva esta semantica.

## UC-L07 - Cambiar velocidad

**Entrada:** velocidad en pasos de 0.05.

**Estados validos:** `ready`, `running`, `waitingForTarget`, `paused`.

**Reglas:** actualizar dominio y clock atomicamente; mantener el mismo tick musical; rechazar valores fuera de rango. El pitch esperado no cambia.

## UC-L08 - Pausar, reanudar y repetir seccion

### Pausar

- Desde estados activos, pausar clock y conservar estado previo como `resumeStatus`.
- El analyzer permanece abierto en pausa de usuario y sus observaciones se ignoran; background, salida de pantalla o error ejecutan UC-L09 y lo detienen.

### Reanudar

- Volver mediante una cuenta atras de un compas; no saltar directamente a `running`.

### Repetir seccion

- Limpiar resultados de la seccion, posicionar en su inicio y ejecutar cuenta atras completa.
- No recrear BLoC, streams o handles si siguen sanos.

## UC-L09 - Detener sesion

**Entrada:** accion de usuario, cambio de modo, lifecycle o final.

**Reglas:** pausar y detener clock, limpiar target, cancelar suscripciones y detener analyzer. Es idempotente. Tras parada voluntaria queda `ready`; tras final natural queda `completed`; tras error queda `failure` recuperable cuando corresponda.

## UC-L10 - Consultar proyeccion de render

**Entrada:** estado de sesion y ventana visible en ticks.

**Salida:** `LessonViewportSlice` inmutable con posicion, ventana de ticks, eventos visibles, target y estado de sesion.

**Reglas:** no contiene coordenadas, colores, textos, XML, streams, engines ni callbacks. Presentation lo mapea a `FretboardRenderModel` y despues a pixeles. El caso de uso filtra eventos por ventana sin copiar toda la cancion en cada frame.

## Matriz de estados

| Estado | Tick | Observacion | Pausa | Velocidad | Stop |
|---|---|---|---|---|---|
| `ready` | ignora | ignora | ignora | permite | permite |
| `countIn` | avanza cuenta | ignora | permite | permite | permite |
| `running` | avanza/bloquea | ignora | permite | permite | permite |
| `waitingForTarget` | congela | valida | permite | permite | permite |
| `validating` | congela | acumula | permite | permite | permite |
| `successFeedback` | congela | ignora | permite | no | permite |
| `reentry` | avanza sin evaluar | ignora | permite | no | permite |
| `paused` | ignora | ignora | reanuda | permite | permite |
| `completed` | ignora | ignora | reinicia | permite | permite |
| `failure` | ignora | ignora | recupera si aplica | no | permite |

## Casos limite cerrados

- Dos notas iguales consecutivas requieren ataques distintos.
- Una ligadura no requiere segundo ataque.
- Un silencio crea hueco, no objetivo.
- Un acorde se evalua por clases tonales, no por duplicados ni cuerda fisica.
- Una grace note se ignora en E08 y no genera objetivo ni cue visual.
- Cambiar velocidad nunca cambia MIDI ni cents objetivo.
- El ruido o una observacion de baja confianza nunca desbloquea.
- Una observacion anterior al comienzo de espera nunca desbloquea.
- Perder permiso o dispositivo detiene recursos y produce `failure` recuperable.
- Salir de la pantalla ejecuta UC-L09 antes de destruir el BLoC.
