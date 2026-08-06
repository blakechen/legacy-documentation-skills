---
name: inventory

description: |
  Scan the repository and build a deterministic inventory of the software
  project. This Skill discovers observable facts only and creates the
  foundation for all downstream documentation Skills.

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - inventory
  - repository
  - discovery
  - reverse engineering
  - documentation

supported-languages:
  - Java
  - Kotlin
  - Scala
  - COBOL
  - C#
  - VB.NET
  - Node.js
  - TypeScript
  - JavaScript
  - Python
  - Go
  - PHP

outputs:
  - docs/overview/system-overview.md
  - docs/overview/project-structure.md
  - docs/overview/repository-inventory.md
  - docs/overview/file-statistics.md
---

# Objective

Create a complete inventory of the repository.

This Skill documents only observable facts.

Business logic is outside the scope of this Skill.

---

# Responsibilities

This Skill SHALL

- identify projects

- identify modules

- identify programming languages

- identify build systems

- identify dependency managers

- identify configuration files

- identify deployment descriptors

- identify infrastructure files

- identify documentation

- identify test projects

- identify scripts

- identify containers

- identify CI/CD

- identify generated source

- identify external libraries

This Skill SHALL NOT

- infer business rules

- analyse SQL logic

- analyse APIs

- analyse architecture

- analyse workflows

- create specifications

---

# Inputs

Repository Root

Source Code

Configuration Files

Build Files

Documentation

Scripts

Container Files

CI/CD Definitions

---

# Deliverables

docs/overview/

system-overview.md

project-structure.md

repository-inventory.md

file-statistics.md

---

# Evidence Rule

Every observation must reference actual files.

Never infer missing information.

Unknown is acceptable.

Guessing is prohibited.

---

# Completion Criteria

Inventory is complete when

every directory

every project

every module

every build file

every configuration

has been indexed.

---

# Dependencies

None

---

# Required By

technology-discovery

architecture-discovery

module-analysis

database-analysis

interface-analysis

business-rule-extraction

sequence-discovery

specification-generation
