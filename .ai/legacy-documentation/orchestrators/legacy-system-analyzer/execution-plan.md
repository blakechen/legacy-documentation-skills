# Execution Plan

## Prerequisites

Fact extraction completed.

`docs/facts/types.psv` exists and is non-empty.

Bytecode oracle status recorded and not `FAILED`.

`docs/verification-tier.txt` written, naming tier A or B.

Where commands cannot be run at all, the tier is C, declared by hand, and
shared/verification-tiers.md governs what the run may claim.

Inventory completed.

Technology completed.

Architecture completed.

Custom Framework detected (if applicable).

---

## Artifact Enumeration (MANDATORY before Phase 2)

After Architecture Discovery, the `artifact-enumeration` Skill runs.

Enumerate ALL transaction/action classes.

Enumerate ALL DB object subclasses.

Enumerate ALL servlets.

This step MUST complete before any Phase 2 Skill begins.

### Gate Criteria (added from lessons learned)

Enumeration is NOT complete until:

1. A persistent file exists at `docs/enumeration/transaction-classes.txt` with one entry per class.

2. A persistent file exists at `docs/enumeration/db-object-classes.txt` with one entry per DB object.

3. A persistent file exists at `docs/enumeration/servlet-classes.txt` with one entry per servlet.

4. Each file contains `ClassName|Path`, and `ClassName|Path|TargetTable` for DB objects.

5. `docs/enumeration/enumeration-evidence.psv` records, per entry, the
   inheritance depth and how it was discovered.

6. The count is confirmed against the BYTECODE ORACLE, not against a second
   text search. See shared/enumeration-first.md. Where no compiled artefact
   exists, the report says so and the run is not described as verified.

7. `docs/enumeration/priority.txt` exists, so that batching is by value
   rather than by package name.

If the gate is not met, downstream Skills MUST NOT proceed.

---

## Batching Rules (added from lessons learned)

For repositories where enumeration yields > 50 primary units:

0. Archetype clustering runs first. A copy-and-paste family is one full-depth
   document plus delta documents, not N full documents.
   See shared/archetypes.md.

1. The orchestrator SHALL divide work into batches by PRIORITY, from
   `docs/enumeration/batches.txt`. See shared/prioritization.md.

2. Each batch SHALL complete ALL downstream Skills (Module Analysis → Business Rules → Sequence → Specification) for its scope before moving to the next batch.

3. Progress SHALL be tracked in `docs/gap-analysis/progress.md` with format: `Batch N: [package] [X/Y classes] [status]`.

4. The orchestrator SHALL NOT produce a single system-level document as a substitute for per-unit documents.

5. If the AI context window is insufficient for a full batch, the batch SHALL be subdivided further.

---

## Parallel Execution

Nothing executes before Fact Extraction.

Allowed

Module Analysis

Database Analysis

Interface Analysis

may execute independently after

Architecture Discovery AND Artifact Enumeration AND Archetype Clustering.

Reflexion Check may run in parallel with Phase 2, but its divergences and
absences MUST be resolved before Specification Generation.

---

Business Rule Extraction

must wait until

Module

Database

Interface

complete.

Must iterate EVERY transaction class.

---

Sequence Discovery

must wait until

Business Rules complete.

Must generate one sequence per major transaction.

---

Per-Transaction Specification Generation

must wait until

all documentation Skills complete.

Must generate one spec per transaction class.

---

System Specification Generation

must wait until

Per-Transaction Specifications complete.

---

Characterization Test Generation

must wait until

Per-Transaction Specifications complete.

---

Gap Analysis

always executes last.

Must verify per-transaction document count matches enumeration count.

Must run tools/verify/staleness.sh, then tools/verify/depth_checks.sh,
and report their exit statuses. Assertion is not verification.