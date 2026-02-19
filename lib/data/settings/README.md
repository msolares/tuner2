# Persistencia de calibracion A4 (T011)

Reglas:
- Rango valido A4: `430.0` a `450.0` Hz.
- Valor default: `440.0` Hz.
- Guardado persistente: `SharedPreferences` clave `tuner.a4_hz`.

Comportamiento:
- Al iniciar BLoC se intenta restaurar A4 persistido.
- Al cambiar A4 se normaliza al rango y se guarda.
- Si persiste/lectura falla, el flujo de afinacion sigue con default actual.
