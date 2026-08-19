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

- analyse validation logic (owned by module-analysis, see shared/logic-depth.md)

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

---

# Prompt

# Database Analysis

---

## Goal

Analyse the persistence layer.

Do not analyse business logic.

---

## Step 1

Identify Database Technologies

Examples

DB2

Oracle

SQL Server

MySQL

PostgreSQL

SQLite

MongoDB

Redis

Record

Technology

Version if known

Evidence

---

## Step 2

Identify Schemas

Locate

Schema

Catalog

Database Name

Owner

Record

Schema

Purpose

Evidence

---

## Step 3

Identify Tables

For every table

Record

Table Name

Schema

Primary Key

Foreign Keys

Indexes

Referenced By

Mapped Entity

Evidence

---

## Step 4

Identify Views

Record

View Name

Purpose

Referenced By

Evidence

---

## Step 5

Identify Sequences

Record

Sequence

Consumers

Evidence

---

## Step 6

Identify Entity Mapping

Locate

@Entity

@Table

@Column

@OneToOne

@OneToMany

@ManyToOne

@ManyToMany

XML Mapping

MyBatis Mapper

Custom DB Object Pattern (CRITICAL):

If the system uses a base class with programmatic field definitions:

- Find the base DB object class (e.g., SecuredDBObject, DBObject).

- Enumerate EVERY subclass.

- For each subclass, extract:

  - Table name from setTargetTable()

  - Fields from addField() calls (name, type, length, nullable, description)

  - Primary key from addKey()

  - Description from setDescription()

- This is equivalent to DDL extraction.

Apply shared/enumeration-first.md for DB object classes.

Record

Entity

Mapped Table

Fields with types

Relationships

Evidence

---

## Step 7

Identify Repository Layer

Locate

Repository

DAO

Mapper

JdbcTemplate

NamedParameterJdbcTemplate

Record

Repository

Entity

Database Access Pattern

Evidence

---

## Step 8

Identify SQL

Locate

SELECT

INSERT

UPDATE

DELETE

MERGE

WITH

CALL

Stored Procedure

Native Query

Named Query

Record

Location

Operation

Tables

Evidence

Do not explain business purpose.

---

## Step 9

Identify Transactions

Locate

@Transactional

TransactionTemplate

JTA

EJB Transaction

Record

Transaction Type

Location

Evidence

---

## Step 10

Generate ER Diagram

Generate Mermaid ER Diagram.

Only include verified entities.

Do not infer cardinality.

Unknown cardinality is acceptable.

---

## Output Rules

Never infer business meaning.

Never explain business rules.

Never explain transaction workflow.

Never infer hidden table relationships.

Never generate sequence diagrams.

---

## Required Outputs

Generate

docs/database/database-overview.md

docs/database/table-reference.md

docs/database/entity-mapping.md

docs/database/sql-reference.md

docs/database/er-diagram.md

---

## Quality Checklist

??Database identified

??Schemas documented

??Tables documented

??Views documented

??Sequences documented

??Repository layer documented

??ORM documented

??SQL documented

??Transactions documented

??Mermaid ER Diagram valid

??Evidence included

??No hallucinations

---

End.
