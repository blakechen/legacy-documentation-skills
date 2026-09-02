---
name: artifact-enumeration

description: |
  Enumerate every primary unit in the repository and persist the master
  lists to disk. This Skill produces the authoritative enumeration files
  that gate all Phase 2 Skills. It counts and locates artifacts only and
  never describes what they do.

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - enumeration
  - transaction
  - servlet
  - db-object
  - gate
  - reverse-engineering

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

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery

shared:
  - enumeration-first
  - custom-framework-recognition
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist

outputs:
  - docs/enumeration/transaction-classes.txt
  - docs/enumeration/db-object-classes.txt
  - docs/enumeration/servlet-classes.txt
  - docs/enumeration/enumeration-report.md
---

# Objective

Build the complete master list of every primary unit in the repository.

This Skill is the gate between Phase 1 and Phase 2.

Apply shared/enumeration-first.md.

Apply shared/custom-framework-recognition.md.

This Skill records identity and location only.

Behaviour, logic and business meaning are outside the scope of this Skill.

---

# Responsibilities

This Skill SHALL

- identify the dispatcher or router class

- identify the transaction base class

- identify the DB object base class

- enumerate EVERY transaction/action class

- enumerate EVERY DB object subclass

- enumerate EVERY servlet

- record the file path of every enumerated class

- record the target table of every DB object where declared

- persist every list to disk as a machine-readable file

- verify each list against an independent scan

- report the verified count of each list

This Skill SHALL NOT

- describe what a class does

- extract business rules

- analyse method logic

- generate per-unit documents

- substitute an approximate count for a list

- stop after a representative sample

---

# Inputs

docs/overview/repository-inventory.md

docs/overview/project-structure.md

docs/overview/technology-stack.md

docs/overview/frameworks.md

docs/architecture/architecture.md

docs/architecture/component-diagram.md

Source Code

Deployment Descriptors

---

# Deliverables

docs/enumeration/

transaction-classes.txt

db-object-classes.txt

servlet-classes.txt

enumeration-report.md

---

# File Format

One entry per line.

Pipe separated.

No header row.

No blank lines.

transaction-classes.txt

`ClassName|relative/path/to/File.java`

servlet-classes.txt

`ClassName|relative/path/to/File.java`

db-object-classes.txt

`ClassName|relative/path/to/File.java|TargetTable`

The third field is present only for db-object-classes.txt.

Write `UNKNOWN` when the target table cannot be determined from the source.

Never omit the field.

---

# Evidence Rule

Every entry must reference a real file.

Every path must resolve from the repository root.

A class that cannot be located is not enumerated.

Unknown is acceptable.

Guessing is prohibited.

---

# Completion Criteria

Enumeration is complete when

docs/enumeration/transaction-classes.txt exists and line count > 0

and

docs/enumeration/db-object-classes.txt exists and line count > 0

and

docs/enumeration/servlet-classes.txt exists and line count > 0

and

every line matches the declared file format

and

every recorded path resolves to an existing file

and

each line count has been verified against an independent scan.

If any condition fails, Phase 2 is BLOCKED.

---

# Dependencies

inventory

technology-discovery

architecture-discovery

---

# Required By

module-analysis

database-analysis

interface-analysis

business-rule-extraction

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

A document that violates a shared rule is INCOMPLETE,
regardless of its content.

---

# Prompt

# Artifact Enumeration Skill

---

## Goal

Produce the authoritative master lists of every primary unit.

Do not document behaviour.

Do not sample.

Enumerate exhaustively.

Persist to disk.

---

## Step 1

Identify the Dispatcher

Locate the class that routes incoming requests to transaction classes.

Search for

a servlet that reads a transaction code parameter

a routing table

a switch or map keyed by transaction code

a factory that instantiates transaction classes by name

a configuration file that maps codes to classes

Record

Dispatcher Class

File Path

Routing Mechanism

Routing Key (parameter name, header, URL segment)

If no dispatcher exists, record `Dispatcher: NONE` and continue.

---

## Step 2

Identify the Base Classes

Locate the transaction base class.

Search for

the supertype of the classes the dispatcher instantiates

an abstract class with a single execute-style entry method

an interface implemented by every action class

Locate the DB object base class.

Search for

an abstract class exposing table name and field definitions

a base DAO or record type

a persistence superclass

Record

Transaction Base Class + File Path

DB Object Base Class + File Path

Detection Evidence

If a custom framework is present, apply shared/custom-framework-recognition.md
before concluding that no base class exists.

---

## Step 3

Enumerate Transaction Classes

Find EVERY class that

extends or implements the transaction base class

or

is referenced by the dispatcher routing mechanism

or

is registered in a routing configuration file

Union the results of all three searches.

Deduplicate by fully qualified class name.

Write one line per class to

`docs/enumeration/transaction-classes.txt`

Format

`ClassName|relative/path/to/File.java`

A count is NOT enumeration.

`grep -c` output is NOT enumeration.

The file must contain the actual names and paths.

---

## Step 4

Enumerate DB Object Classes

Find EVERY class that

extends the DB object base class

or

declares a table mapping annotation

or

is registered in an ORM mapping file

Extract the target table name from each class.

Write one line per class to

`docs/enumeration/db-object-classes.txt`

Format

`ClassName|relative/path/to/File.java|TargetTable`

Write `UNKNOWN` as the target table when it cannot be determined.

Do not infer a table name from the class name.

---

## Step 5

Enumerate Servlets

Find EVERY class that

extends HttpServlet

or

is declared in web.xml

or

carries a servlet annotation

or

is declared in a container-specific deployment descriptor

Write one line per class to

`docs/enumeration/servlet-classes.txt`

Format

`ClassName|relative/path/to/File.java`

---

## Step 6

Independent Verification

For each generated file

count the lines

re-scan the repository with a different search expression

compare the two counts

If the counts differ

report the difference

identify the missing entries

re-scan

Do not proceed while a discrepancy is unresolved.

---

## Step 7

Path Validation

For every entry in every file

confirm the recorded path resolves to an existing file

Remove no entry silently.

An unresolvable path is a defect and must be reported and corrected.

---

## Step 8

Enumeration Report

Generate `docs/enumeration/enumeration-report.md`

Record

Dispatcher Class and Routing Mechanism

Transaction Base Class

DB Object Base Class

Transaction Class Count

DB Object Class Count

Servlet Count

Verification Method used for each count

Unresolved Discrepancies

Classes with UNKNOWN target table

---

## Step 9

Batching Advice

If the transaction class count exceeds 50

propose a batch plan grouped by package or module

record the proposed batches in the enumeration report

Format

`batch N | package | units in batch`

The orchestrator consumes this plan.

This Skill does not execute the batches.

---

# Output Rules

Never describe what a class does.

Never analyse a method.

Never extract a rule.

Never generate a per-unit document.

Never report a count without the corresponding list.

Enumeration only.

---

# Required Outputs

Generate

docs/enumeration/transaction-classes.txt

docs/enumeration/db-object-classes.txt

docs/enumeration/servlet-classes.txt

docs/enumeration/enumeration-report.md

---

# Failure Reporting

If zero transaction classes are found

STOP the pipeline.

Report

- the searches performed
- the base class candidates evaluated
- the dispatcher candidates evaluated
- why each was rejected

Zero transaction classes is a critical failure, not an empty result.

---

# Quality Checklist

☐ Dispatcher identified or explicitly recorded as NONE

☐ Transaction base class identified

☐ DB object base class identified

☐ transaction-classes.txt exists with line count > 0

☐ db-object-classes.txt exists with line count > 0

☐ servlet-classes.txt exists with line count > 0

☐ Every line matches the declared pipe-separated format

☐ Every recorded path resolves to an existing file

☐ Every count independently verified

☐ Enumeration report generated

☐ No approximate counts

☐ No sampling

☐ No behaviour described

---

End.
