# Integrations

How to load this Skill Library into an AI coding tool.

---

## Integration Contract

Every integration does the same three things.

1. Make the AI read `orchestrators/legacy-system-analyzer/skill.md` first.

2. Give the AI read access to `skills/`, `shared/`, `skills/templates/` and
   `tools/`, and permission to RUN the tools. The pipeline's gates are
   commands with exit statuses; a tool the AI may read but not run is a gate
   that will be asserted rather than checked.

3. Point the AI's working output at `docs/` in the target repository.

Nothing in this library is AI-tool-specific.

An AI tool is supported when it can read a Markdown instruction file from the
repository, write files to disk, and execute `python3`.

The last requirement is not optional. See `shared/fact-layer.md`: the
enumeration is queried from a parsed fact base, not searched for in text, and
`shared/mechanical-verification.md` makes every completion gate a command.
An integration that cannot run commands can produce documentation, but it
cannot verify any of it.

---

## Entry Point

The single entry point is

`.ai/legacy-documentation/orchestrators/legacy-system-analyzer/skill.md`

That file names every downstream Skill and the order to run them.

Do not point a tool at an individual Skill unless you intend to run one stage
in isolation.

---

## Tool Entry Files

Each tool loads project instructions from its own file. Place a pointer to the
orchestrator there.

| Tool | Project instruction file |
| --- | --- |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/` |
| Codex CLI | `AGENTS.md` |
| Gemini CLI | `GEMINI.md` |
| Continue.dev | `.continue/` |
| Windsurf | `.windsurf/rules/` |

These filenames are set by each vendor and change between releases.

Verify the current filename against the tool's own documentation before
reporting an integration as broken.

---

## Pointer Content

The pointer is the same for every tool.

```markdown
When asked to document this legacy system, read
`.ai/legacy-documentation/orchestrators/legacy-system-analyzer/skill.md`
and follow it exactly.

Run the Skills in the order that file declares.

Do not skip the Artifact Enumeration gate.

Write all generated documentation under `docs/`.
```

---

## Context Window

The full library does not fit in a single context window for a large
repository.

Load `shared/` rules once at the start of a session.

Load one Skill at a time.

Use the batching rules in
`orchestrators/legacy-system-analyzer/execution-plan.md` when enumeration
yields more than 50 primary units.

---

## Verification

An integration is working when the AI

- reads the orchestrator before analysing any source file

- writes `docs/enumeration/transaction-classes.txt` before Phase 2

- stops when the enumeration gate fails

- produces one document per enumerated unit, not a summary

If the AI produces a single system-level summary instead of per-unit
documents, the Skill Library was not loaded.
