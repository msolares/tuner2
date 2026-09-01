# T061 - Catalogo y contenido inicial de lecciones

## Estado
- todo

## Prioridad
- P1

## Epic
- E08

## Dependencias
- T060

## Objetivo
Crear el catalogo local y la primera clase MusicXML propia para validar el recorrido educativo nota a nota sin audio.

## Entradas
- `specs/epics/E08-aprendizaje-guitarra-musicxml.md`
- `specs/learning/musicxml-profile.md`

## Alcance
- Clase `Pentatonica menor de La - Posicion 1`.
- Recorrido ascendente y descendente de 23 negras en 4/4 a 70 BPM.
- Afinacion estandar, posiciones 5 y 8/7 de la primera posicion y un silencio final.
- Metadata local para UC-L00, documento para UC-L01 y tests de carga.

## Fuera de alcance
- Canciones, acordes, red, progreso, bloqueos, editor de lecciones o audio real.

## Criterios de aceptación
- Todo contenido es propio y parsea sin diagnosticos no esperados.
- Genera 23 `LessonNoteEvent`, `totalTicks = 23040` y ningun acorde o diagnostico.
- Pitch, cuerda y traste son coherentes en todas las notas.
- La clase define titulo, subtitulo, orden, duracion estimada y tipo ejercicio.
- El catalogo depende del puerto de dominio y no filtra rutas a UI.

## Evidencia de cierre
- Pendiente.
