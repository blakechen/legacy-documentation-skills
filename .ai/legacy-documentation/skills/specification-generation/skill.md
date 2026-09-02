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
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction
  - sequence-discovery

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - enumeration-first
  - logic-depth

templates:
  - specification
  - transaction
  - glossary

outputs:
  - docs/specifications/system-specification.md
  - docs/specifications/functional-specification.md
  - docs/specifications/technical-specification.md
  - docs/specifications/module-specifications/
  - docs/specifications/transactions/
  - docs/specifications/api-specification.md
  - docs/specifications/database-specification.md
  - docs/specifications/glossary.md
  - docs/specifications/assumptions.md
  - docs/specifications/limitations.md
---

# Objective

Generate implementation-independent specifications.

Specifications shall be based only on verified documentation.

This Skill does not perform primary source analysis.

Source code may be read only to verify a statement already present in upstream
documentation.

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

- perform primary source analysis (module-analysis owns method-level logic)

- reduce the depth of upstream module documentation

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

---

# Shared Rules

Every output of this Skill SHALL comply with:

- shared/evidence-rules.md
- shared/confidence-scoring.md
- shared/documentation-style.md
- shared/markdown-style.md
- shared/naming-conventions.md
- shared/output-schema.md
- shared/quality-checklist.md
- shared/enumeration-first.md
- shared/logic-depth.md

Document structure SHALL follow:

- skills/templates/specification.md
- skills/templates/transaction.md
- skills/templates/glossary.md

A document that violates a shared rule is INCOMPLETE,
regardless of its content.

---

# Prompt

# Specification Generation

---

# Goal

Generate software specifications using previously generated documentation.

Source code may be read only to verify a statement already present in upstream
documentation. Depth comes from docs/modules/transactions/, not from re-reading source.

Do not infer undocumented behavior.

---

# CRITICAL: Per-Transaction Specifications

Apply shared/enumeration-first.md.

Apply shared/logic-depth.md.

Use skills/templates/transaction.md as the required structure.

1. Obtain the complete transaction class list from Module Analysis.

2. For EVERY transaction class, generate a specification under docs/specifications/transactions/.

3. Each transaction specification SHALL contain:

   - Purpose, entry URL and routing parameters

   - A State Methods index

   - One `### Method:` subsection per method, carrying forward from
     docs/modules/transactions/[ClassName].md:

     * Processing Flow (verbatim or clarified, never shortened)

     * Pseudocode (verbatim)

     * Field Mapping (verbatim)

     * Branches and Conditions

   - In place of Key Source Excerpts, a reference line:

     `Source evidence: ../../modules/transactions/[ClassName].md#method-[name]`

   - Input fields and validation rules

   - Database tables accessed, with operations and columns

   - External system calls

   - Business rules enforced (reference BR-IDs)

   - Output pages/redirects

   - Error handling

   - Security requirements

   - Related sequences (reference)

4. Do NOT produce only a system-level summary. Per-transaction specs are MANDATORY.

5. A specification whose method subsections are shorter than the corresponding
   module document sections is INCOMPLETE.

---

# Input Documents

Read

overview/

architecture/

modules/

database/

integration/

business-rules/

sequence/

Only use verified documentation.

---

# Step 1

Generate System Specification

Include

Purpose

Scope

Architecture Summary

Technology Summary

Major Modules

External Systems

Constraints

Known Limitations

References

---

# Step 2

Generate Functional Specification

Apply shared/logic-depth.md.

Use skills/templates/specification.md as the required structure.

Describe

System Responsibilities

Functional Areas

Actors

Business Capabilities

Business Rules

System Inputs

System Outputs

Dependencies

Referenced Sequences

Referenced APIs

Referenced Database Objects

---

# Step 3

Generate Technical Specification

Apply shared/logic-depth.md.

Use skills/templates/specification.md as the required structure.

Describe

Architecture

Layers

Components

Packages

Technology Stack

Runtime

Deployment Assumptions

Database Technologies

Messaging Technologies

Security Technologies

---

# Step 4

Generate Module Specifications

Generate one document for every module.

Each module shall include

Purpose

Responsibilities

Dependencies

Entry Points

Interfaces

Configuration

Database Objects

Related Business Rules

Related Sequences

Referenced APIs

---

# Step 5

Generate API Specification

Summarize

REST

SOAP

MQ

Kafka

gRPC

File Interfaces

Authentication

Error Handling

Retry

External Systems

---

# Step 6

Generate Database Specification

Summarize

Database Technologies

Schemas

Tables

Views

Sequences

Repositories

Entities

Transactions

Persistence Technologies

ER Diagram Reference

---

# Step 7

Generate Glossary

Collect

Business Terms

Technical Terms

Abbreviations

System Names

Module Names

External Systems

Do not invent terminology.

---

# Step 8

Generate Assumptions

List

Explicit assumptions only.

Never infer.

---

# Step 9

Generate Limitations

Examples

Unknown Modules

Incomplete Evidence

Missing Documentation

Unavailable Configuration

Unresolved References

---

# Output Rules

Every statement must reference previously generated documentation.

Never perform primary source analysis. Read source only to verify an existing statement.

Never summarise away the processing flow, pseudocode or field mapping present in
docs/modules/transactions/. Carry it forward.

Never introduce new business rules.

Never invent requirements.

Never rewrite evidence.

Never remove uncertainty.

---

# Required Outputs

Generate

docs/specifications/system-specification.md

docs/specifications/functional-specification.md

docs/specifications/technical-specification.md

docs/specifications/api-specification.md

docs/specifications/database-specification.md

docs/specifications/glossary.md

docs/specifications/assumptions.md

docs/specifications/limitations.md

docs/specifications/module-specifications/

docs/specifications/transactions/ (one file per transaction class)

---

# Quality Checklist

☐ Functional specification completed

☐ Technical specification completed

☐ Module specifications completed

☐ API specification completed

☐ Database specification completed

☐ Glossary completed

☐ Assumptions documented

☐ Limitations documented

☐ Every statement traceable

☐ No new knowledge introduced

☐ No hallucinations

---

End.
