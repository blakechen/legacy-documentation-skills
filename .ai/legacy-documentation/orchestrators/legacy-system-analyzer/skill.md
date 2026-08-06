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
