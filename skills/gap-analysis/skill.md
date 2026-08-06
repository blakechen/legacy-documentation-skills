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
