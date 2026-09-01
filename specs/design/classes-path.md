# Ruta visual de clases

## Objetivo

Definir el acceso provisional a las lecciones de E08 sin condicionar el futuro sistema de progreso. La referencia de interaccion es un recorrido vertical de botones grandes, cercano al patron de Duolingo, pero con identidad visual propia del proyecto.

## Navegacion

- La barra inferior del shell contiene, de izquierda a derecha: `Afinador`, `Metronomo`, `Clases`.
- El destino `Clases` no solicita microfono al abrirse.
- Tocar un nodo abre una ficha local de la clase con titulo, subtitulo, duracion estimada y accion `Empezar`.
- `Empezar` carga el MusicXML y abre la pantalla horizontal del mastil.
- Volver desde la ficha o desde el mastil retorna a la ruta conservando su posicion de scroll durante la sesion de la app.
- El microfono solo se solicita al iniciar la sesion educativa, nunca al explorar clases.

## Composicion visual

La pantalla de clases se presenta en vertical y admite scroll:

1. Cabecera compacta `Clases` y texto `Aprende paso a paso`.
2. Tarjeta de etapa con titulo `Primeros pasos` y una descripcion breve.
3. Camino central con nodos circulares grandes conectados por una linea suave.
4. Los nodos alternan ligeramente a izquierda y derecha sin superar el ancho accesible.
5. Cada nodo muestra un icono musical y debajo el titulo corto de la clase.

Primer nodo E08:

- Titulo: `Pentatonica menor de La`.
- Subtitulo: `Primera posicion · nota a nota`.
- Duracion estimada: `3 min`.
- Tipo: ejercicio.
- Accion: disponible.

## Estados cerrados E08

- `loading`: esqueletos estables sin desplazar la barra inferior.
- `content`: todos los nodos recibidos por UC-L00 son seleccionables.
- `empty`: mensaje `Todavia no hay clases disponibles`, sin inventar contenido.
- `failure`: mensaje recuperable y boton `Reintentar`.

No existen en E08 estados visuales de completado, bloqueado, estrellas, vidas, racha, porcentaje o posicion de usuario. Cuando se diseñe la API, esos conceptos requeriran contratos y tasks propios.

## Responsabilidad por capa

- Domain entrega `LessonSummary` mediante UC-L00 y no conoce nodos, colores ni rutas.
- Data resuelve metadata y documentos desde assets locales sin exponer sus paths.
- Presentation mapea los summaries a modelos visuales y gobierna loading/content/empty/failure mediante BLoC.
- App conecta destinos y dependencias; no consulta el catalogo directamente.

## Responsive y accesibilidad

- La ruta permanece vertical en movil, tablet y Web; el mastil conserva su especificacion horizontal independiente.
- Objetivo tactil minimo de 48x48 dp; nodo recomendado de 72 dp.
- Orden semantico coincide con `sequenceIndex`, aunque el camino alterne visualmente.
- Cada nodo anuncia titulo, subtitulo, duracion y `Disponible`.
- El significado no depende solo del color y reduce motion elimina animaciones de rebote o recorrido.

## Criterios visuales

- Usa tokens de `AppTheme`; no introduce colores literales fuera del tema.
- Mantiene el aspecto oscuro y luminoso de la referencia aprobada del mastil.
- Las conexiones son decorativas y no participan en hit testing.
- La barra inferior no cambia de altura entre modos.
- No hay scroll horizontal ni overflow en 320 px de ancho.
