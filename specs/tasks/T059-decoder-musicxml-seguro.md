# T059 - Decoder MusicXML seguro y seleccion de tablatura

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057

## Objetivo
Implementar el adaptador MusicXML hasta una representacion interna de data segura, seleccionando parte/staff TAB y rechazando entradas fuera del perfil.

## Entradas
- `specs/learning/musicxml-profile.md`
- `docs/partituras/prueba-tablatura.xml`

## Alcance
- Parseo sin DTD, entidades externas ni red.
- Limites de tamaño y nodos.
- Versiones `score-partwise` admitidas.
- Seleccion por `partId` o descubrimiento TAB.
- Afinacion, capo, transposicion, pitch, string/fret y elementos temporales.
- DTOs privados de data y errores tipados.

## Fuera de alcance
- Expansion de navegacion, entidades finales, DSP o UI.

## Criterios de aceptación
- Ningun tipo XML cruza fuera de data.
- No se hardcodean `P1`, staff 2 o voice 5.
- XML malicioso/externo se rechaza sin acceso de red.
- Pitch/string/fret inconsistentes fallan de forma tipada.
- Fixtures minimos cubren cada rama de parseo.

## Evidencia de cierre
- Pendiente.
