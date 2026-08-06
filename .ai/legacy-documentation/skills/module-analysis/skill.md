---
name: module-analysis

description: |
  Analyse each logical module within the repository and generate
  module-level documentation describing responsibilities, structure,
  entry points, dependencies and public interfaces.

version: 1.0.0

category: architecture

author: Legacy Documentation Skills

tags:
  - module
  - package
  - component
  - documentation
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery

outputs:
  - docs/modules/
  - docs/modules/module-index.md
---

# Objective

Analyse every logical module independently.

The objective is to describe what each module contains,
how it is organized,
and how it interacts with other modules.

Business behaviour is outside the scope of this Skill.

---

# Responsibilities

This Skill SHALL

- identify logical modules

- identify module boundaries

- identify module responsibilities

- identify entry points

- identify exported interfaces

- identify internal components

- identify important classes

- identify package hierarchy

- identify dependencies

- identify shared components

- identify configuration related to the module

This Skill SHALL NOT

- analyse business rules

- explain transaction flow

- analyse SQL

- generate specifications

- analyse validation logic

---

# Inputs

Repository Inventory

Technology Discovery

Architecture Discovery

Source Code

Configuration Files

---

# Deliverables

docs/modules/

module-index.md

One Markdown document for each module.

Example

loan.md

customer.md

payment.md

batch.md

security.md

common.md

---

# Evidence Rule

Every statement must reference observable evidence.

Evidence may include

Directory

Package

Namespace

Configuration

Annotation

Class

Interface

Dependency

Unknown is acceptable.

Never infer module responsibilities beyond available evidence.

---

# Completion Criteria

Every logical module has

- been identified

- been documented

- listed entry points

- listed dependencies

- listed public interfaces

---

# Required By

database-analysis

interface-analysis

business-rule-extraction

sequence-discovery

specification-generation
