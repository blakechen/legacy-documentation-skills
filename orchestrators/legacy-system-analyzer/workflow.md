# Legacy System Analyzer Workflow

---

## Purpose

This workflow coordinates every documentation Skill.

It does not analyse source code.

It only manages execution.

---

## Phase 1

Repository Initialization

Tasks

- locate repository

- verify readable

- create docs directory

- create temporary workspace

Outputs

Repository Ready

---

## Phase 2

Inventory

Execute

inventory

Expected Outputs

docs/overview/system-overview.md

docs/overview/project-structure.md

docs/overview/technology-stack.md

Validation

Inventory completed.

---

## Phase 3

Technology Discovery

Execute

technology-discovery

Expected Outputs

Technology Stack

Framework List

Language Summary

Validation

Frameworks identified.

---

## Phase 4

Architecture Discovery

Execute

architecture-discovery

Expected Outputs

Architecture

Context Diagram

Component Diagram

Dependency Graph

Validation

Architecture complete.

---

## Phase 5

Module Analysis

Execute

module-analysis

Expected Outputs

One document for every major module.

Validation

Every module documented.

---

## Phase 6

Database Analysis

Execute

database-analysis

Expected Outputs

ER Diagram

Table Reference

Entity Mapping

Validation

Persistence documented.

---

## Phase 7

Interface Analysis

Execute

interface-analysis

Expected Outputs

REST

SOAP

MQ

FTP

Batch

Validation

External interfaces documented.

---

## Phase 8

Business Rule Extraction

Execute

business-rule-extraction

Expected Outputs

Business Rule documents.

Validation

Every rule includes evidence.

---

## Phase 9

Sequence Discovery

Execute

sequence-discovery

Expected Outputs

Mermaid Sequence Diagrams.

Validation

Every major flow documented.

---

## Phase 10

Specification Generation

Execute

specification-generation

Expected Outputs

Functional Specification

Technical Specification

Validation

Specifications complete.

---

## Phase 11

Gap Analysis

Execute

gap-analysis

Expected Outputs

TODO.md

Coverage Report

Validation

Every missing artifact identified.

---

# Execution Rules

Execute one Skill at a time.

Do not execute Skills in parallel.

Never skip a dependency.

Never infer outputs.

Never overwrite existing documentation unless regeneration is explicitly requested.

---

# Retry Policy

Recoverable Failure

Retry once.

Fatal Failure

Stop workflow.

Generate execution-report.md

---

# Evidence Policy

Every generated document must contain evidence.

Evidence may include

Class

Package

Method

SQL

Configuration

REST Endpoint

SOAP Service

MQ Queue

File

Build Script

Configuration Property

If evidence cannot be found

write

Unknown

Never guess.

---

# Completion

Workflow finishes after

Gap Analysis completes

and

execution-report.md

has been generated.

End.