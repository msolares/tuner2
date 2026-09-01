# Backlog de Tasks

## Convenciones
- Estado: `todo`, `in_progress`, `blocked`, `done`.
- Prioridad: `P0` alta, `P1` media, `P2` baja.
- Cada task debe incluir evidencia al cerrarse.

## Definition of Done (DoD)
1. Objetivo cumplido segun criterios de aceptacion.
2. Sin decisiones tecnicas abiertas en la task.
3. Evidencia registrada (archivo, test, salida o nota tecnica).
4. Dependencias actualizadas.

## Orden recomendado de ejecucion
T001 -> T002 -> T003 -> T004 -> T005 -> T006 -> T007 -> T008 -> T009 -> T010 -> T011 -> T012 -> T013 -> T014 -> T015 -> T016 -> T017 -> T018 -> T019 -> T020 -> T021 -> T022 -> T023 -> T024 -> T025 -> T027 -> T028 -> T037 -> T038 -> T039 -> T040 -> T051 -> T029 -> T030 -> T026 -> T031 -> T032 -> T033 -> T034 -> T035 -> T036 -> T052 -> T041 -> (T042, T043, T044) -> T045 -> T046 -> T047 -> T049 -> T048 -> T053 -> T054 -> T055 -> T056

## Rama de trabajo E08 - Aprendizaje MusicXML

Esta rama puede comenzar desde la version de afinador elegida por el propietario y no modifica los contratos protegidos de los modos existentes.

```text
T057
├─ T058
├─ T059 → T060 → T061
├─ T062 → T063 → T064
├─ T065
└─ T066

T058 + T066 → T067
T058 → T068
T061 + T067 + T068 → T069
T057 + T061 → T077
(T061, T064, T065, T066, T067, T069) → T070
T070 + T077 → T071
(T060, T061, T062, T064, T065, T071) → T072
```

No iniciar E09 antes de cerrar T072:

```text
T072 → T073 → T074 → T075 → T076
```
