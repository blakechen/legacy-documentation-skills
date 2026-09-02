---
name: architecture-discovery

description: |
  Discover the software architecture by analysing the structural
  organization of the repository. This Skill identifies architectural
  layers, components, dependencies and system boundaries without
  interpreting business logic.

version: 1.0.0

category: architecture

author: Legacy Documentation Skills

tags:
  - architecture
  - component
  - dependency
  - layer
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - custom-framework-recognition
  - mermaid-guidelines
  - logic-depth

templates:
  - architecture

outputs:
  - docs/architecture/architecture.md
  - docs/architecture/component-diagram.md
  - docs/architecture/context-diagram.md
  - docs/architecture/dependency-graph.md
  - docs/architecture/layer-analysis.md
---

# Objective

Identify the structural architecture of the software.

The objective is to describe how the software is organized.

This Skill does not analyse business behaviour.

---

# Responsibilities

This Skill SHALL

- identify architectural layers

- identify application boundaries

- identify modules

- identify components

- identify packages

- identify namespaces

- identify dependencies

- identify shared libraries

- identify reusable components

- identify external systems

- identify deployment boundaries

- identify architectural patterns

This Skill SHALL NOT

- analyse business rules

- analyse transaction flow

- analyse SQL logic

- generate specifications

- infer user workflow

- evaluate implementation quality

---

# Inputs

Repository Inventory

Technology Stack

Source Code

Configuration Files

Build Definitions

---

# Deliverables

docs/architecture/

architecture.md

component-diagram.md

context-diagram.md

dependency-graph.md

layer-analysis.md

---

# Evidence Rule

Every component shall reference evidence.

Examples

Package

Namespace

Directory

Configuration

Annotation

Dependency

Import

Build File

Unknown is acceptable.

Never infer missing architecture.

---

# Completion Criteria

Architecture is complete when

all layers are identified

major components are documented

external systems are listed

dependency graph is generated

architecture diagrams are generated

---

# Required By

artifact-enumeration

module-analysis

database-analysis

interface-analysis

sequence-discovery

specification-generation

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
- shared/custom-framework-recognition.md
- shared/mermaid-guidelines.md
- shared/logic-depth.md

Document structure SHALL follow:

- skills/templates/architecture.md

A document that violates a shared rule is INCOMPLETE,
regardless of its content.

---

# Prompt

# Architecture Discovery

---

## Goal

Discover the structural architecture of the repository.

Focus on software organization.

Do not analyse business behaviour.

---

## Step 1

Identify Architectural Pattern

Examples

Layered Architecture

Hexagonal

Clean Architecture

Onion

MVC

Microservice

Modular Monolith

SOA

Event Driven

Client Server

Custom Dispatcher (Front Controller with transaction routing)

Custom Framework (proprietary base classes and conventions)

Record

Pattern

Evidence

Confidence

---

## Step 1.1

Identify Custom Framework (CRITICAL)

Apply shared/custom-framework-recognition.md.

Search for:

- A central Servlet that dispatches to transaction classes based on request parameters.

- A base transaction class that all business logic extends.

- A base DB object class that all data access extends.

- A custom configuration loader.

If found, record:

- Dispatcher class and routing parameter(s)

- Base transaction class name

- Base DB object class name

- Configuration loader and path

- Factory/registry class (e.g., TrxFactory)

This step is CRITICAL. If a custom framework is detected, ALL downstream Skills must use this information to enumerate artifacts.

---

## Step 2

Identify Layers

Examples

Presentation

Controller

API

Application

Service

Domain

Repository

DAO

Persistence

Infrastructure

Integration

Batch

Scheduler

Security

Shared

For every layer record

Purpose

Location

Evidence

---

## Step 3

Identify Components

Examples

Loan Service

Customer Service

Authentication

Notification

Payment

Reporting

Scheduler

Batch Processor

Record

Component Name

Responsibility

Location

Evidence

---

## Step 4

Identify Package Structure

Document

Top Level Packages

Namespaces

Module Ownership

Shared Packages

Utility Packages

Record

Hierarchy

Purpose

Evidence

---

## Step 5

Identify Dependencies

Document

Module Dependencies

Library Dependencies

Shared Components

Infrastructure Dependencies

Avoid circular dependency assumptions.

Only report observable relationships.

---

## Step 6

Identify External Systems

Examples

Database

REST Services

SOAP Services

IBM MQ

Kafka

LDAP

SMTP

FTP

SFTP

Mainframe

Cloud Services

Record

System

Connection Type

Evidence

---

## Step 7

Generate Layer Analysis

Describe

Responsibilities

Dependency Direction

Layer Isolation

Potential Violations

Evidence

---

## Step 8

Generate Context Diagram

Use Mermaid.

Include

System

Users

External Systems

Databases

Messaging Systems

Only include verified relationships.

---

## Step 9

Generate Component Diagram

Use Mermaid.

Include

Components

Dependencies

Interfaces

External Systems

Do not invent missing components.

---

## Step 10

Generate Dependency Graph

Document

Module Dependencies

Package Dependencies

Shared Libraries

External Dependencies

Only include verified references.

---

## Output Rules

Never describe business rules.

Never describe user workflow.

Never explain transaction flow here. Per-method processing flow is owned by
module-analysis (see shared/logic-depth.md).

Never infer missing components.

Never invent architectural decisions.

---

## Required Outputs

Generate

docs/architecture/architecture.md

docs/architecture/component-diagram.md

docs/architecture/context-diagram.md

docs/architecture/dependency-graph.md

docs/architecture/layer-analysis.md

---

## Mermaid Rules

Component Diagram

- Components only

- Dependency arrows

Context Diagram

- System

- External Systems

- Databases

- Messaging

No sequence diagrams.

No ER diagrams.

---

## Quality Checklist

☐ Architectural pattern identified

☐ Layers documented

☐ Components documented

☐ Package structure documented

☐ External systems documented

☐ Dependency graph completed

☐ Mermaid diagrams valid

☐ Evidence included

☐ No hallucinations

☐ No business rules

---

End.
