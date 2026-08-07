---
name: legacy-system-analyzer

description: |
  Master orchestrator for reverse engineering legacy systems.
  Coordinates every documentation Skill and manages execution
  order, dependencies, validation and final deliverables.

version: 1.0.0

category: orchestrator

author: Legacy Documentation Skills

outputs:
  - docs/

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction
  - sequence-discovery
  - specification-generation
  - gap-analysis

shared:
  - enumeration-first
  - iterative-depth
  - custom-framework-recognition
---

# Objective

Coordinate the complete documentation pipeline.

Never perform repository analysis directly.

Delegate every task to dedicated Skills.

---

# Responsibilities

This Skill SHALL

- execute Skills in dependency order

- validate prerequisite completion

- verify generated outputs

- stop execution on critical failures

- execute independent Skills in parallel where permitted

- collect final documentation

- execute final quality review

This Skill SHALL NOT

- analyse source code

- generate specifications

- extract business rules

- replace downstream Skills

---

# Completion Criteria

Pipeline completed.

All outputs generated.

Gap analysis completed.

Final documentation validated.

---

# Prompt

# Legacy System Analyzer

## Goal

Produce complete documentation for an unknown legacy repository.

Never skip prerequisite Skills.

Always follow dependency order.

Apply shared/enumeration-first.md at every stage.

Apply shared/iterative-depth.md at every stage.

Apply shared/custom-framework-recognition.md at every stage.

---

## Execution Rules

Execute

Inventory

??
Technology Discovery

??
Architecture Discovery (including custom framework detection)

??
Transaction/Action Class Enumeration

??
Module Analysis (per-module AND per-transaction-class)

??
Database Analysis (enumerate ALL DB object classes)

??
Interface Analysis

??
Business Rule Extraction (iterate EVERY transaction class)

??
Sequence Discovery (one sequence per major transaction)

??
Specification Generation (one spec per transaction class)

??
Gap Analysis

---

## Critical: Transaction-Level Depth

After Architecture Discovery, the orchestrator SHALL:

1. Identify the dispatcher/router class and its routing mechanism.

2. Enumerate EVERY transaction/action class referenced by the dispatcher or extending the base transaction class.

3. Pass this complete list to Module Analysis, Business Rule Extraction, Sequence Discovery, and Specification Generation.

4. Each downstream Skill SHALL process EVERY class in the list, not a sample.

---

## Critical: Database Object Enumeration

After identifying the DB object base class:

1. Enumerate EVERY subclass.

2. Extract table name and field definitions from each.

3. Pass the complete list to Database Analysis.

---

## Critical: Enumeration Gate (added from lessons learned)

The orchestrator MUST verify the following BEFORE proceeding to Phase 2:

1. `docs/enumeration/transaction-classes.txt` exists and line count > 0.

2. `docs/enumeration/db-object-classes.txt` exists and line count > 0.

3. `docs/enumeration/servlet-classes.txt` exists and line count > 0.

If these files do not exist, Phase 2 is BLOCKED.

The orchestrator MUST NOT substitute "I identified ~N classes" for an actual persisted file. Approximate counts are NOT enumeration.

---

## Critical: Batching for Scale (added from lessons learned)

When enumeration yields a large number of primary units (e.g., 400+ transaction classes):

1. The orchestrator SHALL NOT attempt to document all classes in a single pass.

2. Instead, divide into batches by package/module group.

3. Complete the FULL pipeline (Module ??Business Rules ??Sequence ??Spec) for each batch before moving to the next.

4. Track batch progress in `docs/gap-analysis/progress.md`.

5. A system-level summary document is produced ONCE at the end, not as a substitute for per-unit documents.

---

Validate every stage before continuing.

If a stage fails,

report

- failed Skill
- reason
- missing evidence
- blocked downstream Skills

Stop on critical failures.

---

## Final Deliverables

Generate

overview/

architecture/

modules/ (including per-transaction documents)

database/ (including complete table reference from DB object classes)

integration/

business-rules/ (per-transaction rules)

sequence/ (per-transaction sequences)

specifications/ (per-transaction specifications)

gap-analysis/

Verify all required documents exist before reporting completion.

Verify transaction class count matches generated document count.
