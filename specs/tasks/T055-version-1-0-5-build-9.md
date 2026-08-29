# T055 - Version 1.0.5 build 9

## Estado
- done

## Prioridad
- P1

## Epic
- E05

## Dependencias
- T054

## Objetivo
Subir la version de la aplicacion de `1.0.4+8` a `1.0.5+9` y mantener sincronizadas las fuentes de version Flutter y Web.

## Alcance
- Actualizar `pubspec.yaml` a `1.0.5+9`.
- Actualizar la etiqueta visible de version.
- Actualizar metadato y cache buster del bootstrap Web.
- Ajustar y ejecutar la prueba de version.
- Generar un build Web verificable.

## Fuera de alcance
- Cambios funcionales o visuales.
- Publicacion en stores o despliegue remoto.

## Criterios de aceptacion
- Flutter, etiqueta visible y HTML Web exponen `1.0.5+9`.
- El cache buster Web usa la nueva version.
- Test de version y build Web quedan en verde.

## Evidencia de cierre
- Version sincronizada en `pubspec.yaml`, `lib/app/app_version.dart` y `web/index.html` como `1.0.5+9`.
- Cache buster Web actualizado a `flutter_bootstrap.js?v=1.0.5.9`.
- `flutter test test/app/app_version_test.dart --no-pub`: 1 test superado.
- `flutter build web --no-pub`: build Web generado correctamente, incluido el dry run de Wasm.
- Verificacion en navegador sobre `http://127.0.0.1:7363/`: etiqueta `v1.0.5+9` visible y consola sin errores.
