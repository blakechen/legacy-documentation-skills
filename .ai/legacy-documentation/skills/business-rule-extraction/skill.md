---
name: business-rule-extraction

description: |
  Extract business rules hidden inside legacy source code,
  database logic, configurations and integration definitions.
  Convert technical implementations into human-readable rules
  with traceable evidence.

version: 1.0.0

category: business-analysis

author: Legacy Documentation Skills

tags:
  - business-rule
  - validation
  - rule-mining
  - reverse-engineering
  - legacy

dependencies:
  - inventory
  - architecture-discovery
  - module-analysis
  - database-analysis
  - interface-analysis

outputs:
  - docs/business-rules/business-rule-index.md
  - docs/business-rules/
---

# Objective

Discover business rules implemented inside the system.

Convert technical conditions into readable rules.

Every rule must be traceable to source evidence.

---

# Responsibilities

This Skill SHALL

- identify conditional logic

- identify validation rules

- identify calculation rules

- identify status transition rules

- identify authorization rules

- identify exception-based rules

- identify configuration-driven rules

- identify database rules

- identify stored procedure rules

- identify integration routing rules

- identify workflow constraints

This Skill SHALL NOT

- modify source code

- generate new business logic

- assume business intent

- invent missing rules

- create functional specifications

---

# Inputs

Source Code

Module Analysis

Database Analysis

Interface Analysis

Architecture Analysis

Configuration Files

SQL

Stored Procedures

Message Definitions

---

# Rule Discovery Sources

Analyse:

## Application Code

Examples:

if

switch

case

enum

validator

exception

assertion

annotation

state machine

## Database Logic

Examples:

SQL CASE

CHECK Constraint

Trigger

Stored Procedure

Function

## Configuration

Examples:

Properties

YAML

XML

Feature Flags

Threshold Values

## Integration

Examples:

Message Routing

Error Code Mapping

Response Handling

---

# Deliverables

docs/business-rules/

business-rule-index.md

BR-001.md

BR-002.md

BR-003.md

---

# Evidence Rule

Every business rule must contain evidence.

Evidence format:

Source File

Class

Method

Line Reference if available

SQL

Configuration Key

Message Definition

---

# Rule Confidence

Each rule must include confidence.

Values:

High

Directly implemented rule.

Medium

Strong evidence but requires interpretation.

Low

Possible rule with incomplete evidence.

---

# Completion Criteria

Business rules are complete when:

- all validation logic reviewed

- all decision points reviewed

- all status changes reviewed

- all calculations reviewed

- all authorization checks reviewed

- evidence recorded

---

# Required By

sequence-discovery

specification-generation

gap-analysis
