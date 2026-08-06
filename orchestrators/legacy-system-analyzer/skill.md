---
name: legacy-system-analyzer
description: |
  Orchestrate the complete reverse engineering workflow for a legacy software
  system by coordinating all documentation Skills.

version: 1.0.0

author: Legacy Documentation Skills

category: orchestrator

tags:
  - legacy
  - reverse-engineering
  - architecture
  - documentation
  - specification
  - modernization

supported-languages:
  - Java
  - Kotlin
  - COBOL
  - C#
  - VB.NET
  - Node.js
  - JavaScript
  - TypeScript
  - Python
  - Go
  - PHP

supported-frameworks:
  - Spring Boot
  - Spring MVC
  - Jakarta EE
  - Java EE
  - WebSphere
  - JBoss
  - Tomcat
  - .NET
  - Express
  - NestJS
  - Django
  - Flask

outputs:
  - docs/overview/
  - docs/architecture/
  - docs/modules/
  - docs/database/
  - docs/integration/
  - docs/business-rules/
  - docs/sequence/
  - docs/specifications/
---

# Objective

Coordinate all documentation Skills.

This Skill MUST NOT perform reverse engineering directly.

Its responsibility is only:

- determine execution order
- validate prerequisites
- execute Skills
- verify outputs
- stop on fatal errors
- produce execution summary

---

# Responsibilities

This orchestrator SHALL

- initialize analysis

- validate repository

- prepare output folders

- execute each Skill

- verify generated documents

- detect missing outputs

- execute Gap Analysis

- produce execution report

This Skill SHALL NOT

- inspect business logic

- analyse source code

- generate architecture

- generate specifications

- infer business rules

Those responsibilities belong to individual Skills.

---

# Execution Pipeline

Execute the following Skills exactly in this order.

1.

inventory

↓

2.

technology-discovery

↓

3.

architecture-discovery

↓

4.

module-analysis

↓

5.

database-analysis

↓

6.

interface-analysis

↓

7.

business-rule-extraction

↓

8.

sequence-discovery

↓

9.

specification-generation

↓

10.

gap-analysis

No Skill may execute before its dependencies are complete.

---

# Preconditions

Repository is available.

Source code can be read.

Output directory is writable.

No generated documents are locked.

---

# Inputs

Repository root.

Existing documentation.

Configuration files.

Build scripts.

Source code.

---

# Outputs

Execution report

Coverage summary

Generated documentation

Gap report

---

# Error Handling

If a Skill fails

stop execution

record failure

record Skill name

record reason

record generated outputs

do NOT continue.

---

# Output Validation

Before marking a Skill complete

verify

required documents exist

required sections exist

markdown syntax valid

Mermaid syntax valid

required directory exists

---

# Completion Criteria

Execution completes only when

every required Skill completed

OR

fatal failure recorded.

---

# Deliverables

docs/

execution-report.md

coverage-summary.md

gap-analysis/

---

# Principles

Deterministic.

Evidence Based.

No Hallucination.

Technology Neutral.

Single Responsibility.

Repeatable.

Reviewable.

---

# Success Criteria

The repository contains a complete documentation set.

All generated documentation is traceable to source code.

Every missing artifact is listed by Gap Analysis.

No undocumented assumptions remain.
