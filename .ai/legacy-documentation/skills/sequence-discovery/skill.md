---
name: sequence-discovery

description: |
  Generate interaction sequences between components by using the
  outputs of previous documentation Skills. Produce deterministic
  Mermaid sequence diagrams describing verified runtime interactions.

version: 1.0.0

category: interaction

author: Legacy Documentation Skills

tags:
  - sequence
  - interaction
  - workflow
  - mermaid
  - reverse-engineering

dependencies:
  - inventory
  - architecture-discovery
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction

outputs:
  - docs/sequence/sequence-index.md
  - docs/sequence/
---

# Objective

Generate interaction sequences.

Describe how components communicate.

Sequence diagrams must be based on verified evidence.

---

# Responsibilities

This Skill SHALL

- identify request flow

- identify response flow

- identify component interactions

- identify database interactions

- identify external system interactions

- identify MQ interactions

- identify scheduler flow

- identify batch execution flow

- identify exception flow

- generate Mermaid sequence diagrams

This Skill SHALL NOT

- invent execution paths

- infer business intent

- generate functional specifications

- modify business rules

- create new architecture

---

# Inputs

Architecture Discovery

Module Analysis

Database Analysis

Interface Analysis

Business Rule Extraction

Existing Source Code (verification only)

---

# Deliverables

docs/sequence/

sequence-index.md

api-sequences.md

mq-sequences.md

batch-sequences.md

exception-sequences.md

---

# Evidence Rule

Every interaction must reference evidence.

Evidence includes

Method Invocation

REST Mapping

MQ Listener

SQL Call

Repository Call

Configuration

Scheduler Definition

Message Producer

Unknown is acceptable.

Never invent missing interactions.

---

# Completion Criteria

Every major interaction documented.

Every sequence validated.

Mermaid diagrams generated.

Evidence recorded.

---

# Required By

specification-generation

gap-analysis

---

# Prompt

# Sequence Discovery

---

# Goal

Generate sequence diagrams describing runtime interactions.

Use outputs from previous Skills as the primary source.

Consult source code when verification is required.

---

# CRITICAL: Per-Transaction Sequences

Apply shared/enumeration-first.md.

1. Obtain the complete transaction class list from Module Analysis.

2. For EVERY major transaction class, generate at least one sequence diagram.

3. Each diagram shall show the complete flow: User ??JSP ??Dispatcher ??Transaction Class ??DB/External ??Response.

4. Include all state transitions within the transaction (e.g., prompt ??checkuser ??confirm ??result).

5. Output one sequence file per transaction class under docs/sequence/transactions/.

---

# Sequence Discovery Process

## Step 1

Identify Interaction Entry Points

Possible sources

REST Endpoint

SOAP Endpoint

MQ Listener

Batch Job

Scheduler

CLI

Servlet

Record

Entry Point

Evidence

---

## Step 2

Identify Participants

Possible participants

User

Browser

External System

API Gateway

Controller

Service

Domain

Repository

DAO

Database

MQ

Batch

Scheduler

Notification

Third-party Service

---

## Step 3

Identify Invocation Chain

Follow verified calls only.

Examples

Controller

??
Service

??
Repository

??
Database

or

REST

??
Controller

??
MQ

??
External System

Never infer missing calls.

---

## Step 4

Identify Database Interaction

Document

Read

Insert

Update

Delete

Stored Procedure

Transaction Boundary (if explicitly identifiable)

---

## Step 5

Identify External Interaction

Document

REST Client

SOAP Client

MQ Producer

MQ Consumer

FTP

SFTP

Kafka

LDAP

SMTP

Record

Protocol

Direction

Evidence

---

## Step 6

Identify Exception Flow

Locate

try

catch

throws

error mapping

fallback

retry

dead letter queue

Document

Trigger

Handler

Outcome

Evidence

---

## Step 7

Generate Mermaid Sequence Diagram

Use

sequenceDiagram

Include

Actor

Participant

Activation

Request

Response

Database

External Systems

Messages

Only include verified interactions.

---

## Step 8

Generate Sequence Summary

Each sequence shall contain

Overview

Trigger

Participants

Preconditions

Interaction Steps

Database Access

External Calls

Exceptions

Evidence

---

# Output Structure

Generate

docs/sequence/

sequence-index.md

api-sequences.md

mq-sequences.md

batch-sequences.md

exception-sequences.md

---

# Mermaid Rules

Every sequence shall

start with an actor

end with a response or completion

show activation where appropriate

avoid inferred messages

avoid omitted participants when evidence exists

---

# Output Rules

Never infer hidden execution paths.

Never invent business workflows.

Never assume asynchronous behaviour.

Never merge unrelated sequences.

Only document evidence-based interactions.

---

# Quality Checklist

??Entry point identified

??Participants identified

??Invocation chain documented

??Database interaction documented

??External interaction documented

??Exception flow documented

??Mermaid valid

??Evidence included

??No hallucinations

??No inferred workflow

---

End.
