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
  - fact-extraction

shared:
  - enumeration-first
  - verification-tiers
  - fact-layer
  - prioritization
  - mechanical-verification
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
  - docs/enumeration/enumeration-evidence.psv
  - docs/enumeration/enumeration-config.psv
  - docs/enumeration/enumeration-report.md
  - docs/enumeration/priority.txt
  - docs/enumeration/batches.txt
  - docs/enumeration/priority-report.md
---

# Objective

Build the complete master list of every primary unit in the repository.

This Skill is the gate between Phase 1 and Phase 2.

Apply shared/enumeration-first.md.

Apply shared/fact-layer.md.

Apply shared/prioritization.md.

Apply shared/custom-framework-recognition.md.

The lists are QUERIED from the factbase produced by `fact-extraction`. They
are not produced by searching source text. See shared/enumeration-first.md,
"Enumeration Is a Query, Not a Search".

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

docs/facts/types.psv exists and the bytecode oracle status is recorded

and

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

Configure the bases.

Write `docs/enumeration/enumeration-config.psv`

    {
      "transaction_base": ["StdTrxObject"],
      "db_object_base":   ["StdDbObject"],
      "servlet_base":     ["javax.servlet.http.HttpServlet"]
    }

A simple name is enough; a base class that lives in a jar is matched as an
`EXTERNAL:` node.

If the bases are not yet known, run Step 4 with no config. The tool proposes
one from the hierarchy and writes it. A proposal is not a conclusion:
review it against Steps 1 and 2 and correct it before continuing.

---

## Step 4

Enumerate.

    sh tools/factbase/enumerate.sh \
        --facts <repo>/docs/facts \
        --out <repo>/docs/enumeration

This writes the three master lists in the documented pipe-separated format,
plus `enumeration-evidence.psv` carrying the provenance of every entry, and
`enumeration-report.md`.

The tool resolves, and the Skill SHALL report:

- transitive subclasses, at any depth below the base
- subclasses of a base class that is not in the source tree
- classes named only by a string literal, through reflection
- string literals that look like unit names but match no known class

---

## Step 5

Read the discovery breakdown.

`enumeration-report.md` records the inheritance depth of every entry.

Every entry with depth > 1 is an entry a `grep "extends <Base>"` would have
missed. State how many there are. If the number is zero in a system with a
custom framework, be suspicious of the configured base rather than pleased.

Every dangling class reference SHALL be resolved: a class outside the scanned
roots, or a dead registration. Record which.

---

## Step 6

Independent Verification

The oracle is the bytecode, not a second search.

`docs/facts/bytecode-verification.md` is produced by the `fact-extraction`
Skill. Read its status.

`VERIFIED` - proceed.

`FAILED` - Phase 2 is BLOCKED. Classes exist in the compiled artefact that
the scan did not find. Resolve before continuing.

`UNAVAILABLE` - proceed, and record in `enumeration-report.md` that the
enumeration rests on lexical extraction alone. Do not call it verified.
This is Tier B.

If this Skill's tools could not be run at all, the enumeration was produced
by reading. That is Tier C, and `enumeration-report.md` SHALL carry the
disclosure in shared/verification-tiers.md verbatim: the enumeration has NOT
been checked for transitive inheritance, out-of-tree base classes, or
reflection registration, and this run cannot say which of them it missed.

Re-scanning the source with a different expression is NOT verification and
SHALL NOT be reported as such.

---

## Step 7

Path Validation

`enumerate.sh` writes only entries whose type came from a parsed file, so
every path resolves by construction.

Confirm the file count independently:

    wc -l docs/enumeration/*.txt

and confirm that every path in every list exists.

An unresolvable path is a defect in the factbase and SHALL be reported.

---

## Step 8

Prioritise.

    sh tools/factbase/prioritize.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --enumeration <repo>/docs/enumeration \
        [--usage usage.csv --usage-map codes.csv] [--since 3.years]

Produces `priority.txt`, `batches.txt` and `priority-report.md`.

Ask the site for the runtime usage file. It is the strongest of the three
signals and the only one the repository cannot supply. If it is not
available, record that the ranking rests on reachability and churn alone.

Report every unreachable unit by name. Unreachable is a candidate for dead
code, not a verdict: schedulers, message listeners and operator scripts are
entry points this scan does not model.

---

## Step 9

Enumeration Report

`enumerate.sh` generates `docs/enumeration/enumeration-report.md`.

Add to it, by hand:

- which bases were configured and which were auto-detected, and why the
  auto-detected ones were accepted
- the resolution of every dangling class reference
- the oracle status, quoted
- whether a runtime usage file was supplied

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

☐ Every count verified against the bytecode oracle, or the oracle's
  absence recorded

☐ Inheritance depth of every entry recorded

☐ Entries found only through the transitive closure counted and reported

☐ Entries found only through reflection counted and reported

☐ Every dangling class reference resolved

☐ priority.txt, batches.txt and priority-report.md generated

☐ Unreachable units listed by name

☐ Runtime usage file requested, and its absence recorded if not supplied

☐ Enumeration report generated

☐ No approximate counts

☐ No sampling

☐ No enumeration produced by text search alone

☐ No behaviour described

---

End.
