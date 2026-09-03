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
  - fact-extraction
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis

shared:
  - business-rule-criteria
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - enumeration-first
  - iterative-depth
  - logic-depth
  - fact-layer
  - archetypes

templates:
  - business-rule

outputs:
  - docs/business-rules/domain-variables.txt
  - docs/business-rules/domain-variables-report.md
  - docs/business-rules/business-rule-index.md
  - docs/business-rules/transactions/
  - docs/business-rules/cross-cutting.md
  - docs/business-rules/technical-logic.md
---

# Objective

Discover business rules implemented inside the system.

Convert technical conditions into readable rules.

Every rule must be traceable to source evidence.

Apply shared/business-rule-criteria.md.

A rule is a condition that reads or writes a DOMAIN VARIABLE. Everything else
is technical logic and belongs in the module document. Without this test,
every null check becomes a business rule and the rules that matter are lost
in the noise.

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

- record technical logic as a business rule

- report a rule without naming the domain variable it governs

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

transactions/[ClassName].md

cross-cutting.md

One file per transaction class under `transactions/`, named after the class.

Every rule owned by that class lives in that file, in the Business Rule
Document Format, as a `## BR-NNN` section.

Rules that belong to no single transaction class go in `cross-cutting.md`.

BR-IDs are globally unique across all files.

`business-rule-index.md` maps every BR-ID to its owning file.

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

- `docs/business-rules/domain-variables.txt` exists and is non-empty

- every recorded rule names at least one domain variable

- `docs/business-rules/technical-logic.md` exists, so that what was excluded
  is visible and reviewable

- all validation logic reviewed

- all decision points reviewed

- all status changes reviewed

- all calculations reviewed

- all authorization checks reviewed

- evidence recorded

- `ls docs/business-rules/transactions/*.md | wc -l` equals the line count of
  `docs/enumeration/transaction-classes.txt`

A transaction class that yields no rules still gets a file, recording
`No business rules found` and the methods reviewed. A missing file is a gap;
an empty result is a finding.

---

# Required By

sequence-discovery

specification-generation

gap-analysis

---

# Shared Rules

Every output of this Skill SHALL comply with:

- shared/evidence-rules.md
- shared/confidence-scoring.md
- shared/documentation-style.md
- shared/markdown-style.md
- shared/naming-conventions.md
- shared/output-schema.md
- shared/quality-checklist.md
- shared/enumeration-first.md
- shared/iterative-depth.md
- shared/logic-depth.md

Document structure SHALL follow:

- skills/templates/business-rule.md

A document that violates a shared rule is INCOMPLETE,
regardless of its content.

---

# Prompt

# Business Rule Extraction

---

# Goal

Extract business rules from legacy implementation.

Each business rule entry describes WHAT the system enforces, in business terms.

HOW the code implements it is documented by module-analysis in
docs/modules/transactions/[ClassName].md. Do not duplicate that narrative here.

Instead, every rule SHALL link to the method subsection that implements it:

`Implemented at: ../../modules/transactions/[ClassName].md#method-[name] (step N)`

This division is intentional.

It is not a reason for either document to be shallow.

---

# CRITICAL: Exhaustive Extraction

Apply shared/enumeration-first.md.

Apply shared/iterative-depth.md.

1. Obtain the complete transaction class list from Module Analysis.

2. For EVERY transaction class, analyse EVERY state method.

3. Extract ALL conditional logic, validation, calculation, authorization, and status rules.

4. Do NOT stop after finding a few rules. Continue until every transaction class has been reviewed.

5. Write one file per transaction class to
   `docs/business-rules/transactions/[ClassName].md`, iterating the complete
   list in `docs/enumeration/transaction-classes.txt`.

6. Every transaction class in that list gets a file, including classes that
   yield no rules.

---

# Rule Discovery Process

## Step 0

Derive the domain variables.

    python3 tools/factbase/domain_variables.py \
        --db <repo>/docs/facts/factbase.sqlite \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/business-rules/domain-variables.txt

This produces the set of DB columns, input fields and configuration keys the
business owns, each with its evidence.

The list is derived from code and is therefore incomplete wherever a field
name is built dynamically. Add such names by hand and record why.

No rule extraction begins before this file exists.

---

## Step 0b

Apply the test.

For every candidate condition, ask:

> Which domain variable does this condition read or write?

Names one          -> business rule. Record the variable in the evidence.

Names none         -> technical logic. Record it in
                      `docs/business-rules/technical-logic.md` with a count
                      per unit, not as a rule.

Cannot tell        -> record as a rule with confidence Low and state what
                      evidence is missing. Do not drop it silently.

See shared/business-rule-criteria.md for the always-technical and
always-business lists.

---

## Step 1

Analyse Conditional Logic

Search:

if

else

switch

case

ternary

guard clause

validation method


Example:

Source:

if(amount > 1000000)

requireApproval();


Convert:

Rule:

Large transaction requires approval.

Domain variable:

TRSFAMT (input-field), LIMIT_CTL.DAILY_MAX (db-column)

Evidence:

Class

Method

Line range

Outcome when true, outcome when false

Counter-example, which is NOT a rule:

Source:

if(acctNo == null) return;

No domain variable is read for a business decision; this is a guard. It is
recorded in technical-logic.md and appears in the module document's
Processing Flow, not here.


---

# Step 2

Analyse Validation

Search:

Validator

validate

check

verify

assert

throw exception


Identify:

Input limitation

Required field

Format restriction

Range limitation

Dependency rule


---

# Step 3

Analyse Status Rules

Search:

enum

status

state

transition

workflow


Identify:

Allowed states

Forbidden transitions

State conditions


Example:

PENDING

→
APPROVED

Only after manager approval.

---

# Step 4

Analyse Calculation Rules

Search:

Arithmetic

Formula

Percentage

Interest

Amount

Balance

Rate


Document:

Input

Formula

Output

Evidence


---

# Step 5

Analyse Authorization Rules

Search:

Role

Permission

Authority

User Level

Access Control


Document:

Actor

Permission

Condition

Evidence


---

# Step 6

Analyse Database Rules

Search:

CHECK

Trigger

Stored Procedure

Function

Constraint


Document:

Rule

Object

Condition

Evidence


---

# Step 7

Analyse Configuration Rules

Search:

threshold

limit

switch

feature flag

properties

yaml


Document:

Configuration

Meaning

Usage

Evidence


---

# Step 8

Analyse Exception Rules

Search:

Exception

Error Code

Error Message

Catch


Convert:

Technical Exception

into

Business Constraint

only if evidence supports it.


---

# Business Rule Document Format

Each rule is a section inside its owning file, not a standalone document.

Use `## BR-NNN` as the section heading so the anchor is stable.

Each rule must contain:

```

# BR-ID

BR-001


## Name

Rule Name


## Description

Human readable rule.


## Category

Validation

Calculation

Authorization

Workflow

Restriction

Integration


## Condition

When does this rule apply?


## Action

What happens?


## Evidence

Source:

Class:

Method:

File:

SQL:

Configuration:


## Implemented At

../../modules/transactions/[ClassName].md#method-[name], step N


## Source

path/to/Class.java:120-128


## Confidence

High / Medium / Low

```

---

# Output Rules

Never write:

"The system probably..."

"The developer intended..."

"It seems..."

Use:

"The code enforces..."

only when evidence exists.


---

# Forbidden

Do not:

invent business meaning

guess domain terminology

rename entities without evidence

infer user requirements

---

# Quality Checklist

☐ Rule has ID

☐ Rule has description

☐ Rule has condition

☐ Rule has action

☐ Rule has evidence

☐ Rule links to its implementing method subsection (Implemented At)

☐ Confidence assigned

☐ No assumptions

☐ No invented business meaning

☐ Source traceable

☐ One file per transaction class under docs/business-rules/transactions/

☐ File count matches docs/enumeration/transaction-classes.txt line count

☐ Every BR-ID resolvable from business-rule-index.md

---

End.
