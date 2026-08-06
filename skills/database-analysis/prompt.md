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

Record

Entity

Mapped Table

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

✓ Database identified

✓ Schemas documented

✓ Tables documented

✓ Views documented

✓ Sequences documented

✓ Repository layer documented

✓ ORM documented

✓ SQL documented

✓ Transactions documented

✓ Mermaid ER Diagram valid

✓ Evidence included

✓ No hallucinations

---

End.