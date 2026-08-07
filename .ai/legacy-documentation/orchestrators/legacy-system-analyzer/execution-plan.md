# Execution Plan

## Prerequisites

Inventory completed.

Technology completed.

Architecture completed.

Custom Framework detected (if applicable).

---

## Artifact Enumeration (MANDATORY before Phase 2)

After Architecture Discovery:

Enumerate ALL transaction/action classes.

Enumerate ALL DB object subclasses.

Enumerate ALL servlets.

This step MUST complete before any Phase 2 Skill begins.

### Gate Criteria (added from lessons learned)

Enumeration is NOT complete until:

1. A persistent file exists at `docs/enumeration/transaction-classes.txt` with one entry per class.

2. A persistent file exists at `docs/enumeration/db-object-classes.txt` with one entry per DB object.

3. A persistent file exists at `docs/enumeration/servlet-classes.txt` with one entry per servlet.

4. Each file contains `ClassName|Path` (and optionally `|TargetTable` for DB objects).

5. The line count of each file is verified against an independent scan.

If the gate is not met, downstream Skills MUST NOT proceed.

---

## Batching Rules (added from lessons learned)

For repositories where enumeration yields > 50 primary units:

1. The orchestrator SHALL divide work into batches by module/package.

2. Each batch SHALL complete ALL downstream Skills (Module Analysis → Business Rules → Sequence → Specification) for its scope before moving to the next batch.

3. Progress SHALL be tracked in `docs/gap-analysis/progress.md` with format: `Batch N: [package] [X/Y classes] [status]`.

4. The orchestrator SHALL NOT produce a single system-level document as a substitute for per-unit documents.

5. If the AI context window is insufficient for a full batch, the batch SHALL be subdivided further.

---

## Parallel Execution

Allowed

Module Analysis

Database Analysis

Interface Analysis

may execute independently after

Architecture Discovery AND Artifact Enumeration.

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

Gap Analysis

always executes last.

Must verify per-transaction document count matches enumeration count.