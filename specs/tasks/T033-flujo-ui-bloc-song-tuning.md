# T033 - Flujo UI y BLoC para consulta por cancion

## Estado
- todo

## Prioridad
- P0

## Epic
- E06

## Dependencias
- T032, T027

## Objetivo
Agregar en UI un campo de texto y un boton para consultar afinacion de guitarra por cancion, con flujo de estado desacoplado del afinador en tiempo real.

## Entradas
- `lib/presentation/screens/tuner_screen.dart`
- `lib/presentation/bloc/`
- Contratos de T031 y servicio de T032

## Alcance
- Definir eventos/estado para song tuning en BLoC dedicado o modulo separado de presentacion.
- Renderizar input de nombre de cancion y boton de consulta.
- Mostrar estados de carga, exito y error recuperable.
- Mostrar resultado de afinacion en formato claro para guitarra (ejemplo: E A D G B E).

## Fuera de alcance
- Rediseno global de pantalla fuera del bloque de song tuning.
- Navegacion multipantalla para historial o favoritos.

## Entregables
- Componente UI con text field + boton funcional.
- Flujo de estado conectado al servicio de dominio.
- Tests de BLoC/widget para exito, validacion de input vacio y error.

## Criterios de aceptacion
- Boton deshabilitado cuando input esta vacio o hay consulta en curso.
- Al enviar una cancion valida se muestra afinacion de guitarra o error manejado.
- El flujo de afinador en vivo (start/stop y estados existentes) no sufre regresiones.
- `flutter test` verde en modulos impactados.

## Riesgos
- Colision de estados si se mezcla en el mismo BLoC del afinador principal.
- Sobrecarga visual en pantalla principal sin jerarquia clara.

## Plan de implementacion
1. Definir modelo de estado/eventos para song tuning.
2. Integrar form en pantalla con validaciones basicas.
3. Conectar dispatch de evento con servicio de dominio.
4. Agregar pruebas de comportamiento UI/BLoC.

## Evidencia de cierre
- Pendiente.

