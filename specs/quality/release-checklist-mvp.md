# Checklist release MVP (T019)

## Go/No-Go global

- [ ] CI verde en branch candidata.
- [ ] Sin errores bloqueantes abiertos P0/P1.
- [ ] Evidencias de tasks T001-T020 registradas.

## Android

- [ ] Permiso de microfono solicitado y manejado.
- [ ] Start/Stop estable en 3 ciclos consecutivos.
- [ ] Indicadores nota/cents/in-tune visibles.
- [ ] Cambio de A4 en caliente funcional.
- [ ] Error de permiso/audio muestra mensaje recuperable.

## iOS

- [ ] Permiso de microfono solicitado y manejado.
- [ ] Start/Stop estable en 3 ciclos consecutivos.
- [ ] Indicadores nota/cents/in-tune visibles.
- [ ] Cambio de A4 en caliente funcional.
- [ ] Error de permiso/audio muestra mensaje recuperable.

## Web

- [ ] Navegadores baseline validados (Chrome/Edge/Safari/Firefox).
- [ ] Flujo con gesto de usuario para iniciar audio.
- [ ] Degradacion controlada en permisos denegados.
- [ ] Indicadores nota/cents/in-tune visibles.

## Evidencia minima por release

- [ ] Link a pipeline CI del commit candidato.
- [ ] Capturas/video corto de flujo Start/Stop por plataforma.
- [ ] Registro de pruebas de ruido y nota sostenida.
- [ ] Validacion de politica de errores (`T013`).

## Decision final

- `GO`: todos los checks en verde.
- `NO-GO`: cualquier item critico pendiente.
