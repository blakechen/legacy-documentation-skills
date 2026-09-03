---
name: fact-extraction

description: |
  Build the deterministic fact base for the repository before any
  documentation Skill runs. Parses source, resolves the type hierarchy,
  computes the transitive closure, and verifies the result against
  compiled artefacts. Produces facts only; describes nothing.

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - factbase
  - parsing
  - deterministic
  - verification
  - reverse-engineering

supported-languages:
  - Java

dependencies:
  - inventory

shared:
  - fact-layer
  - mechanical-verification
  - evidence-rules
  - confidence-scoring
  - quality-checklist

outputs:
  - docs/facts/files.jsonl
  - docs/facts/types.jsonl
  - docs/facts/methods.jsonl
  - docs/facts/calls.jsonl
  - docs/facts/literals.jsonl
  - docs/facts/manifest.json
  - docs/facts/factbase.sqlite
  - docs/facts/bytecode-verification.md
---

# Objective

Establish, by parsing, every fact that later Skills would otherwise establish
by reading.

Apply shared/fact-layer.md.

This Skill runs a program. It does not analyse code itself.

---

# Responsibilities

This Skill SHALL

- run the Layer 1 extractor over the declared source roots

- build the factbase and its transitive-closure tables

- run the bytecode oracle when compiled artefacts exist

- report the resolution statistics and every unresolved supertype

- record the commit and per-file content hashes

- stop the pipeline when the oracle disagrees with the source scan

This Skill SHALL NOT

- describe what any class does

- name a business concept

- decide which classes are transaction units

- interpret anything

---

# Inputs

Source Code

Compiled classes, jars, wars (when present)

docs/overview/repository-inventory.md

docs/overview/technology-stack.md

---

# Deliverables

docs/facts/

files.jsonl

types.jsonl

methods.jsonl

calls.jsonl

literals.jsonl

manifest.json

factbase.sqlite

bytecode-verification.md

---

# Prompt

# Fact Extraction Skill

## Step 1

Identify the source roots.

Read `docs/overview/project-structure.md`.

Exclude build output, dependencies and generated sources.

Record the roots used.

## Step 2

Extract.

    python3 tools/factbase/extract_java.py \
        --repo <repo> --out <repo>/docs/facts --source-root <root>

Report the counts the tool prints.

Report every entry in `manifest.json` under `parse_errors`. A parse error is
a hole in the factbase and SHALL be named, not summarised.

## Step 3

Build the factbase.

    python3 tools/factbase/build_factbase.py \
        --facts <repo>/docs/facts --db <repo>/docs/facts/factbase.sqlite

Report `resolution_stats`.

An `ambiguous` count above zero means two types share a simple name and a
supertype reference could not be resolved. Name them.

An `external` count is normal: it is how a base class that ships in a jar is
recorded. Those become `EXTERNAL:<SimpleName>` nodes and the closure still
forms through them.

## Step 4

Verify against bytecode.

    python3 tools/factbase/verify_bytecode.py \
        --repo <repo> --db <repo>/docs/facts/factbase.sqlite \
        --out <repo>/docs/facts/bytecode-verification.md

Three outcomes, and all three SHALL be reported literally:

`VERIFIED` - compiled classes agree with the source scan.

`FAILED` - a class exists in bytecode that the scan did not find, or a
supertype disagrees. STOP. The enumeration cannot be trusted. Report the
disagreements and resolve them before continuing.

`UNAVAILABLE` - no compiled artefact was found. Continue, but every later
report SHALL state that the enumeration rests on lexical extraction alone.
Do not write the word "verified" anywhere in that run.

## Step 5

Report.

State

- source roots scanned
- file, type, method, call and literal counts
- parse errors, listed
- resolution statistics
- oracle status, quoted exactly

---

# Completion Criteria

`docs/facts/factbase.sqlite` exists.

Type count > 0.

`docs/facts/bytecode-verification.md` exists and its status is recorded.

Oracle status is not `FAILED`.

---

# Required By

artifact-enumeration

architecture-discovery

module-analysis

database-analysis

business-rule-extraction

gap-analysis

---

# Quality Checklist

☐ Source roots recorded

☐ Extractor run and counts reported

☐ Parse errors listed individually

☐ Factbase built

☐ Resolution statistics reported

☐ Ambiguous resolutions named

☐ Bytecode oracle run or its absence recorded

☐ Oracle status quoted verbatim

☐ No class described

☐ No business meaning assigned

End.
