---
name: spec-task-executor
description: Execute or close a specs/tasks T0XX item in this repository with strict scope, dependency checks, tests, evidence, and status updates. Use when the user asks to implement, continue, finish, or validate a numbered repository task.
---

# Spec Task Executor

Execute exactly one task.

## Start

1. Read `AGENTS.md` and `specs/tasks/README.md` completely.
2. Read the task, all declared input specs and its epic completely.
3. Inspect every dependency task status. Do not assume completion from code presence.
4. Restate the task using the prompt template from `AGENTS.md`.
5. Change status from `todo` to `in_progress` before implementation.

If the task is already `in_progress`, preserve existing user work and determine remaining acceptance criteria. If it is `done`, verify rather than redo unless the user explicitly reopens it.

## Execute

- Implement only `## Alcance` and explicit acceptance criteria.
- Treat `## Fuera de alcance` as a hard boundary.
- Never combine a convenient adjacent task.
- Follow `$project-clean-architecture` for all code changes.
- Add tests when behavior changes; do not defer required coverage to the quality task.
- Preserve unrelated dirty-worktree changes.

## Close

1. Run every gate named by the task and relevant global gates.
2. Record exact evidence: files, test commands/results, fixtures/devices and known limitations that remain inside contract.
3. Confirm every acceptance criterion and dependency.
4. Mark `done` only when nothing required remains.

Do not mark `done` for partial work, unavailable mandatory platforms, failing tests or open decisions. Leave `in_progress` and report the concrete gap unless the task meets the repository's blocked policy.
