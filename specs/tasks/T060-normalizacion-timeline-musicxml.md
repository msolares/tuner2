# T060 - Normalizacion temporal y navegacion MusicXML

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T059

## Objetivo
Convertir el DTO MusicXML a `LessonChart` canonico de 960 PPQ, sin duplicar pentagramas y con navegacion lineal determinista.

## Entradas
- `specs/learning/musicxml-profile.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Cursor por voz con `backup`, `forward` y `chord`.
- Conversion exacta de divisions/tuplets.
- Fusion de ties y agrupacion de acordes.
- Grace notes opcionales.
- Repeats y endings 1/2.
- Tempo/meter maps, secciones, IDs de instancia y totalTicks.
- Normalizacion acotada de medidas irregulares del fixture real.

## Fuera de alcance
- D.S./Coda, audio o evaluacion musical.

## Criterios de aceptación
- Salida cumple todas las invariantes de T057.
- Repeticiones se expanden sin IDs duplicados.
- Tablatura estandar duplicada no crea eventos dobles.
- Resolucion no exacta y navegacion no soportada producen error.
- El fixture real alcanza los resultados normativos documentados.

## Evidencia de cierre
- Pendiente.
