---
name: gap-analysis

description: |
  Perform a comprehensive quality review of all generated
  documentation. Verify documentation coverage, consistency,
  completeness and traceability across every generated artifact.

version: 1.0.0

category: quality

author: Legacy Documentation Skills

tags:
  - quality
  - review
  - coverage
  - consistency
  - traceability
  - documentation

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

outputs:
  - docs/gap-analysis/gap-report.md
  - docs/gap-analysis/coverage-report.md
  - docs/gap-analysis/consistency-report.md
  - docs/gap-analysis/traceability-report.md
  - docs/gap-analysis/depth-report.md
  - docs/gap-analysis/todo.md
---

# Objective

Evaluate the generated documentation.

This Skill performs quality assurance only.

Source code may be read ONLY for two mechanical checks:

1. counting the public methods declared in a primary unit class

2. confirming that a quoted `file:line` excerpt resolves to the quoted text

Interpreting logic, judging correctness, or writing documentation from source
is FORBIDDEN.

---

# Responsibilities

This Skill SHALL

- verify documentation coverage

- verify document consistency

- verify traceability

- verify required deliverables

- identify undocumented artifacts

- identify orphaned documents

- identify conflicting documentation

- identify missing references

- generate improvement recommendations

This Skill SHALL NOT

- generate new documentation

- analyse business logic (counting methods and resolving quoted line ranges is not analysis)

- modify existing documents

- infer missing information

- rewrite specifications

---

# Inputs

All generated documentation.

---

# Deliverables

docs/gap-analysis/

gap-report.md

coverage-report.md

consistency-report.md

traceability-report.md

depth-report.md

todo.md

---

# Evidence Rule

Every reported issue shall reference

Document

Section

Related Artifact

Reason

Never report unsupported issues.

---

# Completion Criteria

Coverage verified.

Consistency verified.

Traceability verified.

Improvement list generated.

Quality report completed.

---

# Prompt

# Gap Analysis

---

# Goal

Perform a complete documentation quality review.

Review documentation.

Source code may be read ONLY to count public methods in a primary unit class and to
confirm that a quoted `file:line` excerpt resolves to the quoted text.

Never interpret logic. Never judge correctness. Never write documentation from source.

---

# Review Scope

Review

overview/

architecture/

modules/

database/

integration/

business-rules/

sequence/

specifications/

---

# Step 1

Coverage Review

Verify

Every module documented.

Every transaction class documented (compare to enumeration list).

Every interface documented.

Every database object documented (compare to DB object enumeration).

Every business rule documented.

Every sequence documented.

Every specification generated.

Per-transaction specifications generated for every transaction class.

Report missing artifacts.

Report count mismatches between enumeration lists and generated documents.

A file that exists but is not depth-complete counts as MISSING for coverage purposes.
See Step 1b.

---

# Step 1b

Depth Review

Apply shared/logic-depth.md.

For EVERY file in docs/modules/transactions/ and docs/specifications/transactions/,
evaluate the Definition of Depth-Complete and record one row:

| Unit | Methods in Source | Method Subsections | Flows >=3 Steps | Pseudocode Blocks | Excerpts with file:line | Field Mapping Tables | Depth-Complete |
|------|-------------------|--------------------|-----------------|-------------------|-------------------------|----------------------|----------------|

Checks

1. `### Method:` subsection count equals the public method count in the source class.
   Mismatch = CRITICAL.

2. Each subsection's Processing Flow has at least 3 numbered steps, or the explicit
   trivial-method sentence. Otherwise = CRITICAL.

3. Each subsection has a non-empty pseudocode fenced block. Otherwise = CRITICAL.

4. Each subsection has at least one excerpt matching `path:line` and the excerpt
   resolves to the quoted text, or the explicit no-critical-logic sentence.
   Otherwise = HIGH.

5. Each subsection has a Field Mapping table with at least one row. Otherwise = HIGH.

6. Specification subsections are not shorter than the module subsections.
   Otherwise = HIGH.

Report

Depth-complete unit count over total enumerated unit count.

The full list of units failing each check.

Depth-Complete Rate = depth-complete units / enumeration line count.

If Depth-Complete Rate is below 100%, the pipeline is NOT complete,
even when every file exists.

---

# Step 2

Consistency Review

Verify

Module names are consistent.

API names are consistent.

Database object names are consistent.

Business rule identifiers are unique.

Sequence names are consistent.

Specification references are valid.

Report inconsistencies.

---

# Step 3

Traceability Review

Verify

Architecture references modules.

Modules reference interfaces.

Modules reference database objects.

Business rules reference evidence.

Sequences reference business rules.

Specifications reference architecture.

Specifications reference modules.

Specifications reference business rules.

Specifications reference sequences.

Every relationship shall be traceable.

---

# Step 4

Cross-reference Validation

Check

Module ??Database

Module ??API

Module ??Sequence

Business Rule ??Module

Business Rule ??Database

Business Rule ??Sequence

API ??Sequence

Database ??Specification

Architecture ??Specification

Report missing references.

---

# Step 5

Document Completeness

Verify required sections.

Examples

Overview

Purpose

Responsibilities

Evidence

Dependencies

References

Unknown sections

Report incomplete documents.

---

# Step 6

Orphan Detection

Detect

Unused module documents

Unused sequence diagrams

Unreferenced business rules

Unreferenced APIs

Unreferenced database objects

Duplicate documentation

Report findings.

---

# Step 7

Quality Metrics

Generate

Documentation Coverage

Reference Coverage

Traceability Coverage

Diagram Coverage

Evidence Coverage

Document Completeness

---

# Step 8

Generate TODO

Prioritize

Critical

High

Medium

Low

Each TODO shall include

Issue

Reason

Related Document

Suggested Action

Priority

---

# Output Rules

Never invent missing information.

Never modify documentation.

Never rewrite evidence.

Never infer undocumented relationships.

Only report observable gaps.

---

# Required Outputs

Generate

docs/gap-analysis/gap-report.md

docs/gap-analysis/coverage-report.md

docs/gap-analysis/consistency-report.md

docs/gap-analysis/traceability-report.md

docs/gap-analysis/depth-report.md

docs/gap-analysis/todo.md

docs/gap-analysis/progress.md

---

# Enumeration-to-Document Verification (added from lessons learned)

The Gap Analysis Skill MUST perform the following numeric checks:

1. Count lines in `docs/enumeration/transaction-classes.txt` ??expected transaction doc count.

2. Count files in `docs/modules/transactions/*.md` ??actual transaction doc count.

3. Count files in `docs/business-rules/transactions/*.md` ??actual BR doc count.

4. Count files in `docs/sequence/transactions/*.md` ??actual sequence doc count.

5. Count files in `docs/specifications/transactions/*.md` ??actual spec doc count.

6. Count lines in `docs/enumeration/db-object-classes.txt` ??expected DB entries.

7. Count entries in `docs/database/table-reference.md` ??actual DB entries.

8. A file that exists but is not depth-complete (Step 1b) counts as MISSING for
   check 2 and check 5.

If ANY actual count < expected count, report as CRITICAL gap with exact numbers.

Coverage and depth are separate gates. Both must pass.

---

# Quality Checklist

??Coverage verified

??Consistency verified

??Traceability verified

??Cross-reference validated

??Orphans detected

??Duplicate documents detected

??Quality metrics generated

??TODO prioritized

??Enumeration-to-document count verified

??Depth verified (shared/logic-depth.md)

??Depth-Complete Rate reported

??No hallucinations

---

End.
