# Sequence Discovery

---

# Goal

Generate sequence diagrams describing runtime interactions.

Use outputs from previous Skills as the primary source.

Only consult source code when verification is required.

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

↓

Service

↓

Repository

↓

Database

or

REST

↓

Controller

↓

MQ

↓

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

✓ Entry point identified

✓ Participants identified

✓ Invocation chain documented

✓ Database interaction documented

✓ External interaction documented

✓ Exception flow documented

✓ Mermaid valid

✓ Evidence included

✓ No hallucinations

✓ No inferred workflow

---

End.