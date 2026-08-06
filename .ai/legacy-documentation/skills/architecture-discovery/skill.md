---
name: architecture-discovery

description: |
  Discover the software architecture by analysing the structural
  organization of the repository. This Skill identifies architectural
  layers, components, dependencies and system boundaries without
  interpreting business logic.

version: 1.0.0

category: architecture

author: Legacy Documentation Skills

tags:
  - architecture
  - component
  - dependency
  - layer
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery

outputs:
  - docs/architecture/architecture.md
  - docs/architecture/component-diagram.md
  - docs/architecture/context-diagram.md
  - docs/architecture/dependency-graph.md
  - docs/architecture/layer-analysis.md
---

# Objective

Identify the structural architecture of the software.

The objective is to describe how the software is organized.

This Skill does not analyse business behaviour.

---

# Responsibilities

This Skill SHALL

- identify architectural layers

- identify application boundaries

- identify modules

- identify components

- identify packages

- identify namespaces

- identify dependencies

- identify shared libraries

- identify reusable components

- identify external systems

- identify deployment boundaries

- identify architectural patterns

This Skill SHALL NOT

- analyse business rules

- analyse transaction flow

- analyse SQL logic

- generate specifications

- infer user workflow

- evaluate implementation quality

---

# Inputs

Repository Inventory

Technology Stack

Source Code

Configuration Files

Build Definitions

---

# Deliverables

docs/architecture/

architecture.md

component-diagram.md

context-diagram.md

dependency-graph.md

layer-analysis.md

---

# Evidence Rule

Every component shall reference evidence.

Examples

Package

Namespace

Directory

Configuration

Annotation

Dependency

Import

Build File

Unknown is acceptable.

Never infer missing architecture.

---

# Completion Criteria

Architecture is complete when

all layers are identified

major components are documented

external systems are listed

dependency graph is generated

architecture diagrams are generated

---

# Required By

module-analysis

database-analysis

interface-analysis

sequence-discovery

specification-generation
