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

Record

Pattern

Evidence

Confidence

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

Never explain transaction flow.

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

✓ Architectural pattern identified

✓ Layers documented

✓ Components documented

✓ Package structure documented

✓ External systems documented

✓ Dependency graph completed

✓ Mermaid diagrams valid

✓ Evidence included

✓ No hallucinations

✓ No business rules

---

End.