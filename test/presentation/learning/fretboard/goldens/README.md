# Goldens del mastil educativo

Las cuatro referencias se generan deliberadamente al ejecutar el comando
manual de T068 con `--update-goldens`. Antes de aceptarlas deben compararse con
`specs/design/assets/learning-fretboard-concept.png` y confirmar:

- seis cuerdas visibles de 6 grave a 1 aguda;
- los tres tonos del acorde alineados en la linea de ejecucion;
- trastes legibles sin depender solo del color;
- ausencia de overflow en 640x360, 844x390, 1024x768 y 1440x900.

Tras esa revision se ejecuta el mismo archivo sin `--update-goldens`.
