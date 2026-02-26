# T034 - Validacion de calidad para song tuning OpenAI

## Estado
- todo

## Prioridad
- P1

## Epic
- E06

## Dependencias
- T033

## Objetivo
Validar calidad funcional y tecnica del flujo de song tuning con foco en robustez, costo de tokens y experiencia de error recuperable.

## Entradas
- Implementacion de T031, T032, T033
- `specs/quality/dart-test-plan.md`
- `specs/quality/ci-gates.md`

## Alcance
- Ejecutar pruebas funcionales con canciones conocidas y casos ambiguos.
- Verificar limites configurados de tokens y timeout por consulta.
- Verificar resiliencia ante fallos de red y respuestas no parseables.
- Registrar evidencia tecnica de consumo y comportamiento.

## Fuera de alcance
- Cambios de arquitectura fuera del feature.
- Automatizacion de benchmark de costo multi-modelo.

## Entregables
- Evidencia de pruebas manuales/automaticas del flujo song tuning.
- Ajustes finales de mensajes de error y fallback UX.
- Nota tecnica de limites operativos (token budget y timeout).

## Criterios de aceptacion
- Casos de exito y error principales cubiertos con evidencia.
- Configuracion de costo por consulta documentada y aplicada en runtime.
- Sin crash ante API key ausente, timeout, 429 o respuesta fuera de esquema.
- `flutter analyze` y `flutter test` verdes en modulos impactados.

## Riesgos
- Costo mayor al esperado si cambia el modelo o schema de salida.
- Respuestas inconsistentes en canciones con multiples afinaciones publicadas.

## Plan de implementacion
1. Ejecutar matriz minima de pruebas funcionales y de error.
2. Ajustar limites de tokens/timeout y mensajes UX.
3. Registrar evidencia final y estado del hito.

## Evidencia de cierre
- Pendiente.

