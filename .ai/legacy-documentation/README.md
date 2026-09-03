# Legacy Documentation Skills

AI-powered reverse engineering framework for legacy software systems.

Generate architecture documentation, module documentation,
database specifications, API documentation,
business rules and functional specifications from an existing codebase.

---

# Features

Supports

- Java

- Spring Boot

- Jakarta EE

- WebSphere

- EJB

- COBOL

- C#

- .NET

- Node.js

- Python

- Go

- PHP

- Kotlin

- Scala

---

Produces

- Architecture Documentation

- Module Documentation

- Database Documentation

- API Documentation

- Business Rules

- Sequence Diagrams

- Functional Specification

- Technical Specification

- Gap Analysis

---

Repository

↓

Fact Extraction (parse; build factbase; verify against bytecode)

↓

Inventory

↓

Technology Discovery

↓

Architecture Discovery

↓

Artifact Enumeration (queried from the factbase)

↓

Prioritization

↓

Archetype Clustering

↓

Reflexion Check

↓

Module Analysis

↓

Database Analysis

↓

Interface Analysis

↓

Business Rule Extraction

↓

Sequence Discovery

↓

Specification Generation

↓

Characterization Tests

↓

Gap Analysis (depth and staleness, by tool)

---

Documentation is

- derived from a parsed fact base, not from reading

- independently verified against compiled artefacts

- checked by executable gates, not by assertion

- evidence-based

- implementation-independent

- traceable

- version-pinned, so a citation can be told from a citation that has rotted

---

## Repository Structure

orchestrators/

skills/

skills/templates/

shared/

tools/          deterministic extraction and verification (Python 3, no deps)

examples/

examples/fixtures/   golden cases; `sh tools/selftest.sh`

integrations/

---

## Supported AI

GitHub Copilot

Claude Code

Cursor

Codex CLI

Gemini CLI

Continue.dev

Windsurf

---

## Philosophy

Unknown is preferable to guessing.

Evidence is mandatory.

Every statement must be traceable.

Every Skill has a single responsibility.

A parser establishes facts. A model assigns meaning. Never the other way
round.

A completion claim that no program can refute is not a completion claim.

Six depth-complete documents beat 458 shallow ones.

---

## Requirements

Python 3.8 or later, standard library only.

`javap` and `javac`, when compiled artefacts are to be used as an
independent oracle. Their absence is recorded, not worked around.

Nothing else.

---

## License

MIT