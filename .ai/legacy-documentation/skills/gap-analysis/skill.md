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
  - docs/gap-analysis/todo.md
---

# Objective

Evaluate the generated documentation.

This Skill performs quality assurance only.

It does not analyse source code.

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

- analyse business logic

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

Review documentation only.

Never inspect source code.

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

If ANY actual count < expected count, report as CRITICAL gap with exact numbers.

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

??No hallucinations

---

End.
