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

Every interface documented.

Every database object documented.

Every business rule documented.

Every sequence documented.

Every specification generated.

Report missing artifacts.

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

Module → Database

Module → API

Module → Sequence

Business Rule → Module

Business Rule → Database

Business Rule → Sequence

API → Sequence

Database → Specification

Architecture → Specification

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

---

# Quality Checklist

✓ Coverage verified

✓ Consistency verified

✓ Traceability verified

✓ Cross-reference validated

✓ Orphans detected

✓ Duplicate documents detected

✓ Quality metrics generated

✓ TODO prioritized

✓ No hallucinations

---

End.