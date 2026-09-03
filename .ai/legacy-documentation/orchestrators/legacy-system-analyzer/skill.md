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
  - fact-extraction
  - inventory
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction
  - sequence-discovery
  - specification-generation
  - archetype-clustering
  - reflexion-check
  - gap-analysis

shared:
  - fact-layer
  - mechanical-verification
  - enumeration-first
  - iterative-depth
  - logic-depth
  - business-rule-criteria
  - prioritization
  - archetypes
  - reflexion-model
  - incremental-update
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

Apply shared/fact-layer.md at every stage.

Apply shared/mechanical-verification.md at every stage.

Apply shared/enumeration-first.md at every stage.

Apply shared/iterative-depth.md at every stage.

Apply shared/logic-depth.md at every stage.

Apply shared/custom-framework-recognition.md at every stage.

---

## Execution Rules

Execute

Fact Extraction (parse the source into a factbase; verify against bytecode)

→
Inventory

→
Technology Discovery

→
Architecture Discovery (including custom framework detection)

→
Artifact Enumeration (queried from the factbase; then prioritised)

→
Archetype Clustering (collapse copy-and-paste families)

→
Reflexion Check (test a person's model against the factbase)

→
Module Analysis (per-module AND per-transaction-class, in priority order)

→
Database Analysis (enumerate ALL DB object classes)

→
Interface Analysis

→
Business Rule Extraction (iterate EVERY transaction class)

→
Sequence Discovery (one sequence per major transaction)

→
Specification Generation (one spec per transaction class)

→
Characterization Test Generation

→
Gap Analysis (staleness, then depth; both by tool)

---

## Critical: Facts Before Documentation

Nothing in this pipeline reads source to establish a fact a parser can
establish. See shared/fact-layer.md.

The orchestrator SHALL verify BEFORE Phase 1:

1. `docs/facts/factbase.sqlite` exists and its type count is greater than zero.

2. `docs/facts/bytecode-verification.md` exists.

3. Its status is `VERIFIED` or `UNAVAILABLE`. `FAILED` BLOCKS the pipeline.

4. An `UNAVAILABLE` status is carried into every later report, and the word
   "verified" is not used for that run.

The orchestrator MUST NOT accept "I read the code and found N classes" in
place of a factbase.

---

## Critical: Transaction-Level Depth

After Architecture Discovery, the orchestrator SHALL:

1. Identify the dispatcher/router class and its routing mechanism.

2. Enumerate EVERY transaction/action class, by QUERY against the factbase:
   the transitive closure below the base class, plus classes named only by a
   string literal through reflection. A text search for `extends <Base>` is
   not an enumeration.

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

Artifact Enumeration is owned by the `artifact-enumeration` Skill.

The orchestrator delegates the enumeration itself and verifies the result.

The orchestrator MUST verify the following BEFORE proceeding to Phase 2:

1. `docs/enumeration/transaction-classes.txt` exists and line count > 0.

2. `docs/enumeration/db-object-classes.txt` exists and line count > 0.

3. `docs/enumeration/servlet-classes.txt` exists and line count > 0.

If these files do not exist, Phase 2 is BLOCKED.

The orchestrator MUST NOT substitute "I identified ~N classes" for an actual persisted file. Approximate counts are NOT enumeration.

---

## Critical: Depth Gate

Coverage and depth are separate gates. Both are mandatory. Both are decided
by a program. See shared/mechanical-verification.md.

Before reporting completion, the orchestrator MUST verify:

1. `ls docs/modules/transactions/*.md | wc -l` equals the line count of
   `docs/enumeration/transaction-classes.txt`.

2. `tools/verify/run_depth_checks.py` exits 0 and its report shows a
   Depth-Complete Rate of 100%. The orchestrator SHALL run the command. A
   rate asserted without the command output is not a rate.

3. `tools/verify/staleness.py` exits 0: no document describes source that has
   since changed.

4. Every reflexion divergence and absence has a recorded resolution.

A unit whose document exists but is not depth-complete is NOT done.

Producing 458 shallow documents is a FAILED run, not a partial success.

---

## Critical: Batching for Scale (added from lessons learned)

When enumeration yields a large number of primary units (e.g., 400+ transaction classes):

1. The orchestrator SHALL NOT attempt to document all classes in a single pass.

2. Divide into batches by PRIORITY, from `docs/enumeration/batches.txt`.
   See shared/prioritization.md. Dividing by package name is alphabetical
   order, not a plan.

3. Complete the FULL pipeline (Module → Business Rules → Sequence → Spec) for each batch before moving to the next.

4. Track batch progress in `docs/gap-analysis/progress.md`.

5. A system-level summary document is produced ONCE at the end, not as a substitute for per-unit documents.

6. A batch is complete only when every unit in it is depth-complete.
   Reducing depth to fit a batch is FORBIDDEN. Reduce the batch size instead.

7. Recommended batch size when full depth is required: 5-10 transaction classes per pass.

7a. Before the first batch, collapse copy-and-paste families with
    archetype-clustering. A family of 40 near-identical units is one
    full-depth document and 39 delta documents, not 40 full documents and
    not one summary. See shared/archetypes.md.

8. `docs/gap-analysis/progress.md` SHALL record, per batch:

   `batch N | package | units in batch | depth-complete | remaining | date`

   and a running total `X / Total units depth-complete`.

9. The next pass resumes from the first unit not marked depth-complete.

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

facts/ (factbase, JSONL fact streams, bytecode verification)

overview/

architecture/

enumeration/ (transaction, DB object and servlet master lists)

modules/ (including per-transaction documents)

database/ (including complete table reference from DB object classes)

integration/

business-rules/ (per-transaction rules)

sequence/ (per-transaction sequences)

specifications/ (per-transaction specifications)

characterization/ (executable tests for the documented branches)

model/ (unit-state.json, for incremental re-runs)

gap-analysis/ (including progress.md, depth-report.md, staleness-report.md)

Verify all required documents exist before reporting completion.

Verify transaction class count matches generated document count.

Run every gate command in shared/quality-checklist.md and report its exit
status. Do not assert a gate.

Report the result as "consistent with source; meaning not verified". The
pipeline verifies that documents match the code they cite. It does not
verify that the business meaning assigned to them is right.
