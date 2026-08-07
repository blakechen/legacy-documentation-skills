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
---

# Objective

Analyse every logical module independently.

The objective is to describe what each module contains,
how it is organized,
and how it interacts with other modules.

Business behaviour is outside the scope of this Skill.

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

This Skill SHALL NOT

- analyse business rules

- explain transaction flow

- analyse SQL

- generate specifications

- analyse validation logic

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

Each transaction class document SHALL contain:

- Class name and location

- All public state methods (e.g., prompt, checkuser, confirm, result)

- For each state method: input parameters, validation logic, database access, external calls, redirect/output target

- Related JSP pages

- Related DB objects

- Related properties/configuration

- Error handling

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

Every module document shall contain

# Overview

# Responsibility

# Directory Structure

# Package Structure

# Entry Points

# Public Interfaces

# Internal Components

# Important Classes

# Dependencies

# Configuration

# External Systems

# Evidence

---

## Output Rules

Never infer undocumented behaviour.

Never hallucinate methods or classes that do not exist.

Document observable transaction flow within each class.

Document validation logic found in state methods.

Document SQL and DB object usage found in state methods.

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

??No business rules

??Per-transaction document count matches enumeration count

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
