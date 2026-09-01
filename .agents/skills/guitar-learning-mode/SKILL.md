---
name: guitar-learning-mode
description: Implement or review guitar lessons, MusicXML import, fretboard rendering, note/chord recognition, educational wait/reentry, practice speed, beat maps, or synchronized song audio. Do not use for standalone tuner or metronome work unrelated to learning.
---

# Guitar Learning Mode

Apply after `$project-clean-architecture` and, for a numbered task, `$spec-task-executor`.

## Route to the required contract

Always read `specs/epics/E08-aprendizaje-guitarra-musicxml.md` and `specs/learning/domain-contracts.md`.

- MusicXML/chart: also read `specs/learning/musicxml-profile.md`.
- Session/evaluation: also read `specs/learning/use-cases.md`.
- Fretboard/UI: also read `specs/design/learning-fretboard.md`.
- DSP/chords: also read `specs/quality/learning-mode-test-plan.md` and the relevant Rust/FFI contracts.
- Real audio/beat map/time-stretch: read `specs/epics/E09-audio-real-y-sincronizacion.md`; do not start before T072 is done.

## Non-negotiable invariants

- MusicXML is an input adapter detail; UI receives `LessonChart`/render models.
- Canonical chart time is integer 960 PPQ.
- `TunerEngine` remains unchanged.
- `PerformanceAnalyzer` emits evidence; domain evaluates success.
- Chords are target-directed in E08 and represented by 12 ordered pitch-class strengths.
- Sound can validate pitch classes, not the physical string/fret used.
- The session clock stops at every required target and rejects stale observations.
- Reentry marks the successful target complete before rewinding one beat.
- The painter is frame-efficient and never drives domain time.
- Mobile and Web use the same semantics and shared corpus.
- Unsupported MusicXML or chord content fails explicitly; no silent approximation.

## Product boundaries

E08 contains XML-only lessons, notes, supported chords, speed, wait and reentry. E09 adds pitch-preserving audio synchronization. Games, free chord classification and advanced technique scoring require later epics.

When implementation pressure suggests crossing one of these boundaries, stop and request a spec change rather than adding a hidden extension.
