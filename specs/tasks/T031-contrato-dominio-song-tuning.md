# T031 - Contrato de dominio para song tuning

## Estado
- todo

## Prioridad
- P0

## Epic
- E06

## Dependencias
- T003

## Objetivo
Definir el contrato de dominio para consultar afinacion de guitarra por nombre de cancion, sin acoplar dominio a proveedor externo.

## Entradas
- `specs/epics/E06-song-tuning-openai.md`
- `lib/domain/README.md`
- Contratos actuales en `lib/domain/`

## Alcance
- Crear entidades de dominio para request y resultado de afinacion por cancion.
- Definir interfaz de servicio de dominio para la consulta.
- Definir codigos de error funcionales para respuestas no encontradas o ambiguas.
- Mantener intactos contratos existentes de afinador (`TunerEngine`, `PitchSample`, `TunerSettings`).

## Fuera de alcance
- Implementacion HTTP o integracion OpenAI.
- Cambios UI.

## Entregables
- Nuevos archivos de dominio con contratos de song tuning.
- Documentacion breve en `lib/domain/README.md` sobre el nuevo caso de uso.

## Criterios de aceptacion
- Dominio no contiene dependencias de librerias HTTP/OpenAI.
- El contrato permite representar afinacion estandar y alternativas validas.
- Existe via explicita para errores recuperables y no recuperables.
- `flutter analyze` verde en modulos impactados.

## Riesgos
- Contrato demasiado rigido para afinaciones alternativas por version en vivo/acustica.

## Plan de implementacion
1. Definir estructura de request/response del caso de uso.
2. Definir interfaz de servicio en `domain/services`.
3. Publicar codigos de error de dominio y documentar restricciones.

## Evidencia de cierre
- Pendiente.

