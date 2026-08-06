---
name: database-analysis

description: |
  Analyse the persistence layer of the repository and document
  database objects, entity mappings, repositories, SQL usage and
  persistence technologies.

version: 1.0.0

category: persistence

author: Legacy Documentation Skills

tags:
  - database
  - sql
  - repository
  - dao
  - entity
  - persistence

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - module-analysis

outputs:
  - docs/database/database-overview.md
  - docs/database/table-reference.md
  - docs/database/entity-mapping.md
  - docs/database/sql-reference.md
  - docs/database/er-diagram.md
---

# Objective

Document the persistence layer.

Focus only on data persistence.

Business meaning is outside the scope.

---

# Responsibilities

This Skill SHALL

- identify database technologies

- identify schemas

- identify tables

- identify views

- identify sequences

- identify indexes

- identify entity classes

- identify repository classes

- identify DAO classes

- identify SQL statements

- identify stored procedures

- identify ORM mappings

- identify transaction annotations

- identify database configuration

This Skill SHALL NOT

- infer business rules

- explain SQL intent

- describe workflows

- generate specifications

- analyse validation logic

---

# Inputs

Repository Inventory

Technology Discovery

Architecture Discovery

Module Analysis

Source Code

SQL Files

Database Scripts

Configuration Files

---

# Deliverables

docs/database/

database-overview.md

table-reference.md

entity-mapping.md

sql-reference.md

er-diagram.md

---

# Evidence Rule

Every database object must have evidence.

Evidence includes

DDL

SQL

Annotation

Repository

DAO

XML Mapping

Configuration

Unknown is acceptable.

Never invent relationships.

---

# Completion Criteria

Every persistence technology documented.

Every table indexed.

Every entity documented.

Every repository documented.

ER diagram generated.

---

# Required By

business-rule-extraction

sequence-discovery

specification-generation
