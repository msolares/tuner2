# T027 - Rediseno UI por referencia y suavizado del medidor

## Estado
- in_progress

## Prioridad
- P1

## Epic
- E04

## Dependencias
- T010, T024

## Objetivo
Adaptar la pantalla del afinador a la referencia visual en `.design/screen.png` y suavizar la animacion de barras/indicador de desviacion para evitar saltos bruscos en tiempo real.

## Entradas
- Referencia de diseno: `.design/screen.png`
- Pantalla actual: `lib/presentation/screens/tuner_screen.dart`
- Widgets/estilos relacionados en `lib/presentation/`
- Flujo de estado BLoC en `lib/presentation/` y contratos de `lib/domain/`

## Alcance
- Ajustar layout y jerarquia visual de la pantalla principal del afinador segun la referencia.
- Mantener intactos los contratos de dominio y BLoC existentes.
- Mejorar suavizado visual del medidor (barras/desviacion) sin alterar el significado funcional de `cents`, `in tune` y `out of tune`.
- Evitar cambios de arquitectura fuera de `presentation` salvo necesidad minima justificada.

## Fuera de alcance
- Cambios de contrato en `TunerEngine`, `PitchSample` o API FFI.
- Nuevas funciones de producto no presentes en la referencia (metronomo, canciones, settings funcionales).
- Cambios de deteccion de pitch en Rust o Web engine.

## Entregables
- UI principal del afinador actualizada para aproximarse a `.design/screen.png`.
- Suavizado implementado para la representacion visual de afinacion.
- Tests/widget tests ajustados o nuevos para validar comportamiento visual basico y ausencia de regresiones.

## Criterios de aceptacion
- La pantalla principal refleja estructura visual de la referencia (header, nota central, estado de afinacion, medidor y bloques inferiores).
- El indicador visual de desviacion se percibe fluido en cambios pequenos consecutivos de `cents`.
- No se rompen estados BLoC (`Idle`, `Listening`, `InTune`, `OutOfTune`, `ErrorState`) ni contratos de dominio.
- `flutter analyze` y `flutter test` en verde para los modulos impactados.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Sobreajuste visual a una sola captura sin especificacion completa de interacciones.
- Animaciones demasiado lentas pueden introducir latencia percibida.
- Diferencias de render entre Web y movil.

## Plan de implementacion
1. Mapear componentes actuales vs referencia visual y definir delta minimo.
2. Implementar rediseno de layout/estilos en `presentation`.
3. Introducir mecanismo de suavizado (por ejemplo lerp/filtro exponencial) para barras/offset visual.
4. Validar con pruebas y ajuste fino de parametros de suavizado.

## Evidencia de cierre
- Pendiente.
