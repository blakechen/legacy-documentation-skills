---
name: module-analysis

description: |
  Analyse each logical module within the repository and generate
  module-level documentation describing responsibilities, structure,
  entry points, dependencies and public interfaces.

version: 1.0.0

category: architecture

author: Legacy Documentation Skills

tags:
  - module
  - package
  - component
  - documentation
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery

outputs:
  - docs/modules/
  - docs/modules/module-index.md
  - docs/modules/transactions/
---

# Objective

Analyse every logical module independently.

The objective is to describe what each module contains,
how it is organized,
and how it interacts with other modules.

Business meaning (WHY a rule exists) is outside the scope of this Skill.

Program logic (HOW each method processes a request) is IN scope
and is owned by this Skill.

---

# Responsibilities

This Skill SHALL

- identify logical modules

- identify module boundaries

- identify module responsibilities

- identify entry points

- identify exported interfaces

- identify internal components

- identify important classes

- identify package hierarchy

- identify dependencies

- identify shared components

- identify configuration related to the module

- document, for every primary unit, the step-by-step processing logic of every method

- quote source excerpts evidencing each critical decision, calculation and SQL statement

- map input fields through intermediate variables to database columns and message fields

- restate each method's logic as language-neutral pseudocode

This Skill SHALL NOT

- assign business meaning or business justification to logic (see business-rule-extraction)

- allocate BR-IDs

- design or normalise the data model (see database-analysis)

- generate specifications (see specification-generation)

---

# Inputs

Repository Inventory

Technology Discovery

Architecture Discovery

Source Code

Configuration Files

---

# Deliverables

docs/modules/

module-index.md

One Markdown document for each module.

Example

loan.md

customer.md

payment.md

batch.md

security.md

common.md

---

# Evidence Rule

Every statement must reference observable evidence.

Evidence may include

Directory

Package

Namespace

Configuration

Annotation

Class

Interface

Dependency

Unknown is acceptable.

Never infer module responsibilities beyond available evidence.

---

# Completion Criteria

Every logical module has

- been identified

- been documented

- listed entry points

- listed dependencies

- listed public interfaces

---

# Required By

database-analysis

interface-analysis

business-rule-extraction

sequence-discovery

specification-generation

---

# Prompt

# Module Analysis

---

## Goal

Analyse every logical module in the repository.

Generate one document per module.

Additionally, if the system uses a dispatcher pattern, generate one document per transaction/action class.

Describe module structure AND transaction class behavior.

---

## CRITICAL: Transaction Class Enumeration

Apply shared/enumeration-first.md.

If Architecture Discovery identified a dispatcher pattern:

1. Find EVERY class that extends the base transaction class.

2. Find EVERY class referenced by the dispatcher or its factory/registry.

3. Create a master list of ALL transaction classes with their file paths.

4. Generate one document per transaction class.

Apply shared/logic-depth.md.

Use skills/templates/transaction.md as the REQUIRED structure for each
transaction class document. Do not omit sections.

Each transaction class document SHALL contain:

- Class name, file path, and line range

- A State Methods index listing EVERY public method

- One `### Method:` subsection per indexed method, each containing
  Processing Flow, Pseudocode, Key Source Excerpts, Field Mapping,
  Branches and Conditions, Database Access, External Calls, Error Paths

- An End-to-End Processing Flow narrative across the state methods

- Related JSP pages

- Related DB objects

- Related properties/configuration

This Skill OWNS the method-level logic narrative for the whole pipeline.

Downstream Skills reference these documents. They do not re-derive them.

---

## Step 1

Identify Modules

Possible examples

loan

customer

payment

account

authentication

authorization

batch

report

scheduler

integration

notification

common

shared

security

api

Record

Module Name

Location

Evidence

---

## Step 2

Determine Module Responsibility

Describe

Primary Responsibility

Owned Features

Major Packages

Configuration Files

Avoid assumptions.

Only describe observable responsibilities.

---

## Step 3

Identify Entry Points

Examples

REST Controller

SOAP Endpoint

Message Listener

Batch Job

Scheduler

CLI

Servlet

Filter

Interceptor

Record

Type

Location

Evidence

---

## Step 4

Identify Public Interfaces

Examples

REST API

SOAP Interface

MQ Listener

Published Events

Public Services

Exported Packages

Record

Interface

Purpose

Evidence

---

## Step 5

Identify Internal Structure

Document

Packages

Sub-packages

Major Classes

Interfaces

Configuration

Resources

Utilities

Factories

Builders

Adapters

---

## Step 6

Identify Dependencies

Document

Internal Dependencies

External Dependencies

Shared Modules

Infrastructure Dependencies

Only document observable relationships.

---

## Step 7

Identify Configuration

Locate

application.yml

properties

XML

Annotations

Environment Variables

Module-specific Settings

Record

Purpose

Evidence

---

## Step 8

Generate Module Summary

Include

Purpose

Responsibilities

Entry Points

Interfaces

Dependencies

Important Classes

Configuration

External Systems

Evidence

---

## Output Format

Generate

docs/modules/module-index.md

Generate one document per module.

Generate one document per transaction class under docs/modules/transactions/

Example

loan.md

customer.md

payment.md

security.md

batch.md

transactions/abankLogin.md

transactions/abankPwdChange.md

transactions/AbankSngMergeTrsf.md

---

## Module Document Structure

Use skills/templates/module.md as the required structure.

Every module document shall contain

# Overview

# Responsibility

# Directory Structure

# Package Structure

# Entry Points

# Public Interfaces

# Internal Components

# Important Classes

# Transaction Class Index

# Key Processing Flows

# Dependencies

# Configuration

# External Systems

# Evidence

---

## Output Rules

Document the observable processing logic of every method at the depth defined in
shared/logic-depth.md.

Quote source for every branch, calculation and SQL statement.
Never paraphrase inside a code fence.

Never infer undocumented behaviour.

Never hallucinate methods, classes, tables or columns that do not exist.

Never shorten a document to save space. Depth is the deliverable.

---

## Quality Checklist

??Every module documented

??Responsibilities identified

??Entry points identified

??Public interfaces identified

??Package structure documented

??Dependencies documented

??Configuration documented

??Evidence included

??No hallucinations

??Per-transaction document count matches enumeration count

??Every transaction document matches skills/templates/transaction.md

??Every public method has a `### Method:` subsection

??Every method subsection has Processing Flow, Pseudocode, at least one source excerpt with file:line, and Field Mapping

??No business meaning assigned (BR-IDs referenced only, never invented)

---

## Lessons Learned

### Problem: Module index produced instead of per-transaction documents

The AI produced only `docs/modules/module-index.md` (1 file) rather than one file per transaction class (458 expected). This makes all downstream Skills (Business Rules, Sequence, Specification) impossible to execute correctly.

**Fix**: This Skill's primary deliverable is NOT a single index file. It is:
- `docs/modules/module-index.md` (summary)
- PLUS `docs/modules/transactions/[ClassName].md` for EVERY class in `docs/enumeration/transaction-classes.txt`

Completion criteria: `ls docs/modules/transactions/*.md | wc -l` must equal the line count of `docs/enumeration/transaction-classes.txt`.

### Problem: Scale handled by skipping instead of batching

When facing 458 classes, the correct response is to process in batches (e.g., by package), NOT to produce a summary and declare done.

**Fix**: If batch processing is needed, document progress in `docs/gap-analysis/progress.md` and continue in subsequent passes until all classes are covered.

---

End.
