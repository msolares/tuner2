# Arquitectura limpia obligatoria

## Estado

- Contrato vigente para todo desarrollo nuevo.
- Cualquier excepcion requiere cambiar primero este documento, el epic afectado y `AGENTS.md`.

## Objetivo

Mantener el producto ampliable sin acoplar Flutter, DSP, MusicXML, almacenamiento ni audio de reproduccion. La arquitectura oficial conserva las tres capas existentes y situa los casos de uso dentro de dominio.

```text
presentation  ───────────────► domain ◄─────────────── data
     │                           ▲                       │
     └── UI, BLoC, mappers       │      adapters, DSP ──┘
                                 │
                    app/composition root
```

No existe ninguna dependencia directa `presentation -> data`. El composition root conoce las implementaciones concretas solo para inyectarlas.

## Capas

### `lib/domain`

Contiene:

- Entidades inmutables y value objects.
- Errores tipados de negocio.
- Puertos abstractos hacia audio, tiempo, contenido y persistencia.
- Casos de uso.
- Servicios de dominio puros y maquinas de estado deterministas.

Puede importar exclusivamente Dart SDK y utilidades sin dependencia de plataforma previamente aprobadas. No puede importar Flutter, BLoC, FFI, XML, HTTP, plugins, almacenamiento, `lib/data`, `lib/presentation` ni `lib/app`.

### `lib/data`

Contiene:

- Implementaciones de puertos de dominio.
- Captura de audio y adaptadores de plataforma.
- FFI y serializacion de ABI.
- Decodificacion MusicXML.
- Repositorios concretos y persistencia.
- Implementacion Dart equivalente para Web.

Puede importar dominio. No puede importar presentation ni contener decisiones pedagogicas, estados de pantalla o colores.

### `lib/presentation`

Contiene:

- Pantallas y widgets.
- BLoC, eventos y estados de UI.
- Mappers desde resultados de casos de uso a modelos de renderizado.
- `CustomPainter` y semantica accesible.

Puede importar dominio. No puede importar data, `dart:ffi`, parsers XML, plugins de microfono, almacenamiento ni bindings Rust. Un widget no inicia, detiene ni configura directamente un engine.

### `lib/app`

Es el composition root:

- Selecciona adaptadores por plataforma.
- Construye dependencias.
- Inyecta puertos y casos de uso.
- Gestiona navegacion global y ownership de lifecycle.

No contiene reglas de negocio ni transforma MusicXML.

### `rust/engine`

Contiene DSP y ABI estable para movil. No conoce Flutter, BLoC, lecciones, puntuacion, estados visuales ni MusicXML. Recibe PCM/configuracion y devuelve observaciones numericas o errores tipados.

## Matriz de dependencias

| Origen | Destino permitido | Destino prohibido |
|---|---|---|
| `presentation` | `domain` | `data`, FFI, plugins |
| `domain` | Dart SDK | `presentation`, `data`, Flutter, plataforma |
| `data` | `domain`, plataforma | `presentation` |
| `app` | `domain`, `data`, `presentation` | reglas de negocio |
| Rust DSP | modulos Rust internos | Flutter, XML, UI |

## Reglas de feature

Cada feature nueva se reparte verticalmente entre capas, nunca dentro de una carpeta que mezcle responsabilidades:

```text
lib/domain/learning/
lib/data/learning/
lib/presentation/learning/
test/domain/learning/
test/data/learning/
test/presentation/learning/
```

No se crean carpetas genericas `helpers`, `utils`, `common` o `shared` para saltarse ownership. Una utilidad compartida debe tener propietario, contrato y tests.

## Casos de uso

- La UI expresa intenciones mediante casos de uso o un BLoC que depende de ellos.
- Cada caso de uso tiene entrada y salida tipadas y una unica responsabilidad observable.
- Los casos de uso no aceptan `BuildContext`, widgets, XML nodes, punteros FFI ni tipos de plugins.
- Las decisiones de acierto, espera, reentrada, velocidad y progreso pertenecen a dominio.
- Parsear MusicXML, capturar PCM y ejecutar DSP pertenecen a data.
- Dibujar perspectiva, color y layout pertenece a presentation.

## Contratos y compatibilidad

- Los contratos existentes de afinador y metronomo quedan congelados.
- El modo educativo introduce puertos nuevos; no sobrecarga `TunerEngine` con acordes o estados de leccion.
- Movil y Web implementan el mismo contrato de dominio.
- Un DTO de data se convierte en entidad de dominio antes de salir del adaptador.
- Todo stream define ownership, cierre, semantica de errores e idempotencia de `start/stop`.
- Los timestamps de DSP son monotónicos dentro de una sesion.

## Estado y tiempo

- El reloj musical es autoridad para posicionar eventos; el repaint nunca gobierna la sesion.
- Los eventos de partitura usan ticks enteros canonicos, no milisegundos ni acumulacion de `double`.
- Los renderers interpolan desde una proyeccion inmutable de estado.
- BLoC serializa transiciones; callbacks externos solo producen eventos de entrada.
- Al detener o cambiar de modo se cancelan suscripciones, clocks, audio y handles.

## Politica de cambios

Antes de implementar:

1. Leer `AGENTS.md`, la task y su epic.
2. Confirmar que entradas, salidas, errores e invariantes estan cerrados.
3. Identificar archivos por capa y comprobar que las dependencias son validas.
4. Si falta una decision contractual, cambiar spec en una task separada o marcar bloqueo.

Durante la implementacion no se permite ampliar alcance, modificar contratos protegidos ni introducir una segunda feature.

## Gates obligatorios

- `flutter analyze` limpio.
- `flutter test` completo en verde.
- `cargo test` en verde cuando se toca Rust/FFI/DSP.
- Tests nuevos de dominio ante toda regla nueva.
- Tests de conformidad compartidos para adaptadores movil/Web.
- `git diff --check` limpio.
- Evidencia concreta registrada en la task antes de marcarla `done`.

## Revision arquitectonica

Un cambio se rechaza si ocurre cualquiera de estos casos:

- Presentation importa data.
- Domain conoce Flutter, XML, FFI o plugins.
- Un widget calcula reglas de evaluacion musical.
- Un adaptador decide si el alumno acierta.
- Rust controla una pantalla o una sesion pedagogica.
- El frame de UI actua como reloj musical.
- Se modifica `TunerEngine` para acomodar el modo educativo.
- Se cierra una task sin evidencia o con decisiones pendientes.
