# T071 - Integracion en app shell y ownership de recursos

## Estado
- todo

## Prioridad
- P0

## Epic
- E08, E01

## Dependencias
- T070, T077

## Objetivo
Incorporar el modo educativo a la navegacion conservando afinadores/metronomo y garantizando ownership exclusivo de microfono.

## Entradas
- `lib/presentation/screens/app_shell.dart`
- `specs/architecture/clean-architecture.md`

## Alcance
- Tercer destino inferior `Clases` y composition root por plataforma.
- Navegacion catalogo -> ficha -> pantalla educativa -> catalogo.
- Parada ordenada del modo saliente.
- Permisos/lifecycle compartidos sin acoplar features.
- Recuperacion tras error y retorno a afinador.

## Fuera de alcance
- Rediseñar afinador/metronomo o cambiar contratos existentes.

## Criterios de aceptación
- Afinador, metronomo y leccion nunca poseen simultaneamente el mismo recurso de audio.
- La barra inferior muestra Afinador, Metronomo y Clases sin alterar el estado funcional de los dos primeros.
- Navegar 20 veces no acumula streams/handles.
- Regresion funcional y visual de modos existentes en verde.
- App wiring es el unico lugar que conoce adaptadores concretos.

## Evidencia de cierre
- Pendiente.
