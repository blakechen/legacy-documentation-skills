# Workflow

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

Enumerate ALL transaction/action classes

Enumerate ALL DB object classes

Enumerate ALL servlets

Build master lists

Validation

### Gate Check (added from lessons learned)

Output files MUST exist on disk before proceeding:

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`

Each file MUST contain `ClassName|Path` entries (not just counts).

db-object-classes.txt carries a third field: `ClassName|Path|TargetTable`.

If gate fails → STOP. Do not proceed to Phase 2.

---

## Phase 2

Structural Analysis

Modules

Per-Transaction-Class Analysis

Database (from DB object enumeration)

Interfaces

Validation

---

## Phase 3

Behavior Analysis

Business Rules (per transaction class)

Sequences (per transaction class)

Validation

---

## Phase 4

Documentation

Per-Transaction Specifications

System Specifications

Gap Analysis

Validation

---

Stop immediately if

Inventory fails

or

Architecture cannot be established

or

Transaction class enumeration finds zero classes.