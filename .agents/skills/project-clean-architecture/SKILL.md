---
name: project-clean-architecture
description: Enforce this repository's Clean Architecture when planning, implementing, refactoring, or reviewing Dart, Flutter, Rust, FFI, audio, storage, or cross-platform code. Do not use for conversation-only product brainstorming without repository changes.
---

# Project Clean Architecture

Use this skill for every code or architecture change in the repository.

## Required reading

Read completely, in order:

1. `AGENTS.md`.
2. `specs/architecture/clean-architecture.md`.
3. The active task and its epic/spec inputs.

If any source conflicts, stop implementation and correct the higher-level contract first.

## Preflight

Before editing, state the planned files grouped by ownership:

- Domain: entities, ports, use cases, pure state.
- Data: adapters, parsers, DSP/FFI/platform.
- Presentation: BLoC, render models, widgets/painters.
- App: composition root only.
- Rust: DSP and ABI only.

Reject the plan if a responsibility has no valid owner or if it needs a prohibited dependency.

## Implementation constraints

- Domain must remain independent of Flutter, data, XML, FFI and plugins.
- Presentation must not import data or platform APIs.
- Data implements domain ports and must not import presentation.
- BLoC invokes use cases; it does not recreate business rules.
- Widgets and painters do not control musical time or engines.
- Rust returns observations and errors; it does not decide lesson/UI state.
- Platform implementations must share contract and conformance tests.
- Preserve protected contracts unless the task explicitly changes the governing spec first.
- Do not introduce generic utility folders to hide ownership.

## Verification

Inspect changed imports and dependency wiring. Run the gates required by the task, plus `git diff --check`. For architecture-sensitive changes, add or update tests that fail on the forbidden dependency or misplaced rule.

Report architectural compliance in task evidence: files by layer, ports implemented, protected contracts preserved, and gates run.

## Stop conditions

Stop without inventing a solution when:

- A contract lacks units, ranges, error semantics or ownership.
- The requested change would require presentation-to-data or domain-to-platform coupling.
- Two specs disagree.
- A dependency task is unfinished and its output is required.
- The change would silently widen MusicXML, DSP or platform scope.
