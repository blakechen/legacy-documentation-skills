---
name: specification-generation

description: |
  Generate complete software specifications from the documentation
  produced by previous Skills. This Skill consolidates architectural,
  technical and business knowledge into implementation-independent
  specifications.

version: 1.0.0

category: specification

author: Legacy Documentation Skills

tags:
  - specification
  - documentation
  - functional-spec
  - technical-spec
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction
  - sequence-discovery

outputs:
  - docs/specifications/system-specification.md
  - docs/specifications/functional-specification.md
  - docs/specifications/technical-specification.md
  - docs/specifications/module-specifications/
  - docs/specifications/api-specification.md
  - docs/specifications/database-specification.md
---

# Objective

Generate implementation-independent specifications.

Specifications shall be based only on verified documentation.

This Skill does not analyse source code.

---

# Responsibilities

This Skill SHALL

- consolidate documentation

- generate functional specification

- generate technical specification

- generate module specifications

- generate API specification

- generate database specification

- generate glossary

- generate assumptions

- generate limitations

- identify unresolved questions

This Skill SHALL NOT

- analyse source code

- discover new business rules

- infer undocumented behavior

- modify previous documentation

---

# Inputs

Inventory

Technology Discovery

Architecture Discovery

Module Analysis

Database Analysis

Interface Analysis

Business Rule Extraction

Sequence Discovery

---

# Deliverables

docs/specifications/

system-specification.md

functional-specification.md

technical-specification.md

api-specification.md

database-specification.md

module-specifications/

glossary.md

assumptions.md

limitations.md

---

# Evidence Rule

Every section shall reference previously generated documentation.

Never introduce new facts.

If information is unavailable,

write

Unknown

Do not guess.

---

# Completion Criteria

Functional Specification complete.

Technical Specification complete.

API Specification complete.

Database Specification complete.

Module Specifications complete.

All references valid.

---

# Required By

gap-analysis
