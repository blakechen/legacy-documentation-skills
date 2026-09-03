# Workflow

## Phase 0

Fact Extraction (MANDATORY, runs first)

Skill: fact-extraction

Parse source into a factbase

Resolve the transitive type hierarchy

Verify against compiled artefacts

### Gate Check

`docs/facts/types.psv` MUST exist and be non-empty.

`docs/facts/bytecode-verification.md` MUST exist.

Its status MUST NOT be `FAILED`.

`UNAVAILABLE` is permitted and MUST be carried into every later report.

If the gate fails → STOP. No documentation Skill may run without a factbase.

---

## Phase 1

Repository Discovery

Inventory

Technology

Architecture

Custom Framework Detection

Validation

---

## Phase 1.5

Artifact Enumeration (CRITICAL)

Skill: artifact-enumeration

Query ALL transaction/action classes from the factbase

Query ALL DB object classes

Query ALL servlets

Rank by documentation value

### Gate Check

Output files MUST exist on disk before proceeding:

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`
- `docs/enumeration/enumeration-evidence.psv`
- `docs/enumeration/priority.txt`

Each file MUST contain `ClassName|Path` entries (not just counts).

db-object-classes.txt carries a third field: `ClassName|Path|TargetTable`.

The enumeration report MUST record the inheritance depth of every entry and
the resolution of every dangling class reference.

If gate fails → STOP. Do not proceed.

---

## Phase 1.6

Archetype Clustering

Skill: archetype-clustering

Collapse copy-and-paste families

Assign full-depth or delta mode to every unit

---

## Phase 1.7

Reflexion Check

Skill: reflexion-check

Obtain a module map from a person who knows the system

Compute convergence, divergence, absence

### Gate Check

Every divergence and every absence has a recorded resolution.

An absence caused by missing classes returns the pipeline to Phase 1.5.

---

## Phase 2

Structural Analysis

Modules

Per-Unit Analysis, in priority order

Database (from DB object enumeration)

Interfaces

Validation

---

## Phase 3

Behavior Analysis

Domain Variables (derived, before any rule extraction)

Business Rules (per unit, domain-variable test applied)

Sequences (per unit)

Validation

---

## Phase 4

Documentation

Per-Unit Specifications

System Specifications

Characterization Tests

Gap Analysis (staleness first, then depth; both by tool)

Validation

---

Stop immediately if

Fact extraction fails

or

The bytecode oracle reports FAILED

or

Inventory fails

or

Architecture cannot be established

or

Transaction class enumeration finds zero classes.
