# T064 - Adaptador movil del PerformanceAnalyzer

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T063, T022

## Objetivo
Implementar en data el puerto `PerformanceAnalyzer` para Android/iOS usando captura PCM y el nuevo ABI.

## Entradas
- T063
- `lib/data/audio/`
- `specs/learning/domain-contracts.md`

## Alcance
- Ownership de captura y handle.
- Mapeo target/observaciones/errores.
- Stream compacto y broadcast segun contrato.
- Start/stop/setTarget idempotentes.
- Cancelacion y recuperacion por lifecycle.

## Fuera de alcance
- Web, evaluacion de acierto, BLoC o painter.

## Criterios de aceptación
- Data implementa dominio sin importar presentation.
- Ningun buffer/puntero escapa del adaptador.
- Stop libera captura, suscripciones y handle incluso tras error.
- Tests de conformidad y lifecycle en verde.

## Evidencia de cierre
- Pendiente.
