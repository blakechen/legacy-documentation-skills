# Specification Generation

---

# Goal

Generate software specifications using previously generated documentation.

Do not inspect source code.

Do not infer undocumented behavior.

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

Never analyse source code.

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

---

# Quality Checklist

✓ Functional specification completed

✓ Technical specification completed

✓ Module specifications completed

✓ API specification completed

✓ Database specification completed

✓ Glossary completed

✓ Assumptions documented

✓ Limitations documented

✓ Every statement traceable

✓ No new knowledge introduced

✓ No hallucinations

---

End.