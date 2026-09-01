# Goldens de la pantalla educativa

Las referencias de T069 se generan manualmente después de revisar la pantalla
en 640x360, 1024x600 y 1440x900:

```bash
flutter test test/presentation/learning/screens/lesson_screen_test.dart --update-goldens
```

Después de aceptar visualmente las imágenes, el mismo archivo se ejecuta sin
`--update-goldens` para comprobar regresiones.
