# T024 - Integracion app shell con engines reales

## Estado
- todo

## Prioridad
- P0

## Epic
- E04

## Dependencias
- T021, T023

## Objetivo
Conectar la app shell para usar engines reales por plataforma y eliminar dependencias del engine simulado en ejecucion normal.

## Entregables
- Composicion de dependencias por plataforma en `main.dart`.
- Eliminacion del flujo de permiso demo en pantalla MVP.
- Ajustes de UI/BLoC para iniciar escucha real con permiso runtime.

## Criterios de aceptacion
- En Android/iOS se usa engine movil real y no `SimulatedTunerEngine`.
- El flujo visible de usuario es: pedir permiso -> Start -> feedback real -> Stop.
- El boton demo de permiso queda removido del flujo principal.
- Se conserva contrato de dominio `TunerEngine` sin cambios de firma.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Regresion de experiencia en web si no se mantiene fallback compatible.

## Evidencia de cierre
- Pendiente.
