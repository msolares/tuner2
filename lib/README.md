# Arquitectura por capas (Flutter)

Este modulo usa separacion estricta por capas:

- `presentation`: UI, BLoC y mappers de estado.
- `domain`: entidades, contratos y casos de uso.
- `data`: implementaciones concretas (audio, FFI, adaptadores).

## Reglas de dependencia

- `presentation -> domain`: permitido.
- `presentation -> data`: no permitido.
- `domain -> presentation`: no permitido.
- `domain -> data`: no permitido.
- `data -> domain`: permitido solo para implementar contratos del dominio.
- `data -> presentation`: no permitido.

## Ownership

- `presentation`: equipo app/UI.
- `domain`: ownership compartido app + engine (contratos publicos).
- `data`: equipo de integracion plataforma (audio/ffi/web adapters).
