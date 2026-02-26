# E06 - Song Tuning via OpenAI

## Objetivo
Agregar una capacidad de consulta por nombre de cancion para devolver la afinacion de guitarra recomendada, manteniendo la arquitectura por capas y controlando costo de tokens.

## In scope
- Flujo de consulta por texto desde UI.
- Contrato de dominio para request/response de afinacion por cancion.
- Adaptador `data` para invocar OpenAI con salida estructurada y minima.
- Manejo de errores recuperables (timeout, red, respuesta invalida).

## Out of scope
- Reconocimiento automatico de audio de canciones.
- Historial de busquedas en nube.
- Garantia musicologica absoluta sobre afinaciones alternativas.

## Requisitos tecnicos
- Mantener reglas de dependencia: `presentation -> domain`, `data -> domain`.
- No romper contratos existentes de `TunerEngine` ni BLoC principal del afinador.
- Clave OpenAI gestionada por configuracion segura (sin hardcode en codigo fuente).
- Estrategia de token budget: prompt compacto, salida JSON estricta y limite de tokens de respuesta.

## Criterios de aceptacion
- El usuario puede ingresar una cancion y obtener afinacion de guitarra en un flujo estable.
- El costo por consulta queda acotado por una configuracion explicita de token budget.
- Errores de red/API se muestran sin crash y con opcion de reintento.
