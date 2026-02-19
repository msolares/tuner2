# Matriz de compatibilidad Web MVP (T017)

## Baseline de navegadores soportados

| Navegador | Version minima | Estado MVP |
|---|---:|---|
| Chrome | 120+ | Soportado |
| Edge | 120+ | Soportado |
| Safari | 17+ | Soportado con restricciones de permiso/autoplay |
| Firefox | 121+ | Soportado (latencia puede variar) |

## Restricciones conocidas

- Captura de microfono requiere HTTPS o localhost.
- Requiere gesto de usuario para iniciar audio en algunos navegadores.
- Sample rate efectivo puede ser fijado por el navegador/dispositivo.
- Latencia de buffers en Web puede ser mayor que movil.

## Casos de degradacion esperada

| Caso | Comportamiento esperado |
|---|---|
| Permiso denegado | `ErrorState` recuperable + CTA de reintento |
| Dispositivo sin microfono | mensaje claro y no crash |
| Tab en background | pausa o degradacion de callbacks sin bloqueo |
| WebAudio no disponible | mensaje de no compatibilidad |

## Criterio de aceptacion Web

- Flujo Start/Stop operativo en navegadores baseline.
- Indicadores nota/cents/estado visibles y actualizados.
- Error handling consistente con politica (`T013`).
