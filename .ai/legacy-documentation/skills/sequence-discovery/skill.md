---
name: sequence-discovery

description: |
  Generate interaction sequences between components by using the
  outputs of previous documentation Skills. Produce deterministic
  Mermaid sequence diagrams describing verified runtime interactions.

version: 1.0.0

category: interaction

author: Legacy Documentation Skills

tags:
  - sequence
  - interaction
  - workflow
  - mermaid
  - reverse-engineering

dependencies:
  - inventory
  - architecture-discovery
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction

outputs:
  - docs/sequence/sequence-index.md
  - docs/sequence/
---

# Objective

Generate interaction sequences.

Describe how components communicate.

Sequence diagrams must be based on verified evidence.

---

# Responsibilities

This Skill SHALL

- identify request flow

- identify response flow

- identify component interactions

- identify database interactions

- identify external system interactions

- identify MQ interactions

- identify scheduler flow

- identify batch execution flow

- identify exception flow

- generate Mermaid sequence diagrams

This Skill SHALL NOT

- invent execution paths

- infer business intent

- generate functional specifications

- modify business rules

- create new architecture

---

# Inputs

Architecture Discovery

Module Analysis

Database Analysis

Interface Analysis

Business Rule Extraction

Existing Source Code (verification only)

---

# Deliverables

docs/sequence/

sequence-index.md

api-sequences.md

mq-sequences.md

batch-sequences.md

exception-sequences.md

---

# Evidence Rule

Every interaction must reference evidence.

Evidence includes

Method Invocation

REST Mapping

MQ Listener

SQL Call

Repository Call

Configuration

Scheduler Definition

Message Producer

Unknown is acceptable.

Never invent missing interactions.

---

# Completion Criteria

Every major interaction documented.

Every sequence validated.

Mermaid diagrams generated.

Evidence recorded.

---

# Required By

specification-generation

gap-analysis
