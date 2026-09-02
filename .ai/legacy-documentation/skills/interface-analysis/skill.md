---
name: interface-analysis

description: |
  Analyse all external and internal system integration interfaces.
  Discover communication protocols, message formats, API endpoints,
  messaging systems and integration boundaries.

version: 1.0.0

category: integration

author: Legacy Documentation Skills

tags:
  - integration
  - api
  - rest
  - soap
  - mq
  - jms
  - kafka
  - grpc

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration
  - module-analysis
  - database-analysis

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - mermaid-guidelines

templates:
  - api

outputs:
  - docs/integration/interface-overview.md
  - docs/integration/rest-api.md
  - docs/integration/soap-services.md
  - docs/integration/message-queue.md
  - docs/integration/file-transfer.md
  - docs/integration/external-systems.md
---

# Objective

Document every integration interface.

Focus only on communication between systems.

Business processing is outside the scope.

---

# Responsibilities

This Skill SHALL

- identify REST endpoints

- identify SOAP services

- identify MQ consumers

- identify MQ producers

- identify JMS listeners

- identify Kafka producers

- identify Kafka consumers

- identify FTP integrations

- identify SFTP integrations

- identify File Exchange

- identify gRPC services

- identify GraphQL endpoints

- identify Scheduled Integration Jobs

- identify External Systems

- identify Request Messages

- identify Response Messages

- identify Message Formats

- identify Authentication Methods

This Skill SHALL NOT

- analyse business rules

- explain business meaning

- analyse SQL logic

- generate specifications

- infer message semantics

---

# Inputs

Repository Inventory

Technology Discovery

Architecture Discovery

Module Analysis

Database Analysis

Source Code

Configuration Files

Integration Definitions

---

# Deliverables

docs/integration/

interface-overview.md

rest-api.md

soap-services.md

message-queue.md

file-transfer.md

external-systems.md

---

# Evidence Rule

Every interface must reference observable evidence.

Evidence may include

Controller

Annotation

WSDL

OpenAPI

Swagger

MQ Configuration

Listener

Producer

Scheduler

XML

Properties

YAML

Unknown is acceptable.

Never invent interfaces.

---

# Completion Criteria

Every integration technology documented.

Every external system identified.

Every endpoint documented.

Every messaging interface documented.

Every file integration documented.

---

# Required By

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
- shared/mermaid-guidelines.md

Document structure SHALL follow:

- skills/templates/api.md

A document that violates a shared rule is INCOMPLETE,
regardless of its content.

---

# Prompt

# Interface Analysis

---

## Goal

Analyse every integration interface.

Focus on technical communication only.

Do not explain business behaviour.

---

## Step 1

Identify REST APIs

Locate

@RestController

@RequestMapping

@GetMapping

@PostMapping

@PutMapping

@DeleteMapping

@Path

OpenAPI

Swagger

Servlet-based URL patterns (e.g., /servlet/ClassName?param=value)

Record

Endpoint

Method

Path

Consumes

Produces

Authentication

Evidence

---

## Step 2

Identify SOAP Services

Locate

@WebService

@WebMethod

WSDL

JAX-WS

CXF

Axis

Record

Service

Operation

Endpoint

Evidence

---

## Step 3

Identify Message Queue

Locate

IBM MQ

JMS

ActiveMQ

RabbitMQ

Kafka

Azure Service Bus

AWS SQS

Record

Queue

Topic

Producer

Consumer

Listener

Configuration

Evidence

---

## Step 4

Identify File Transfer

Locate

FTP

SFTP

File Polling

Directory Watch

Shared Folder

Batch Import

Batch Export

Record

Direction

File Pattern

Location

Evidence

---

## Step 5

Identify External Systems

Locate

REST Client

SOAP Client

MQ Connection

Database Link

LDAP

SMTP

Payment Gateway

Identity Provider

Cloud Services

Record

System

Protocol

Evidence

---

## Step 6

Identify Authentication

Examples

Basic Auth

OAuth2

JWT

Mutual TLS

API Key

LDAP

Kerberos

SAML

Record

Authentication Type

Evidence

---

## Step 7

Identify Message Formats

Locate

JSON

XML

CSV

Fixed Length

EDI

Protocol Buffers

Avro

Record

Format

Producer

Consumer

Evidence

---

## Step 8

Identify Retry Strategy

Locate

Retry

Dead Letter Queue

Redelivery

Backoff

Circuit Breaker

Fallback

Record

Mechanism

Evidence

---

## Step 9

Generate Integration Summary

Include

REST

SOAP

MQ

Kafka

JMS

FTP

SFTP

gRPC

GraphQL

External Systems

Authentication

Message Formats

Evidence

---

## Output Rules

Never explain business rules.

Never infer message meaning.

Never describe transaction flow.

Never generate sequence diagrams.

Never infer undocumented protocols.

---

## Required Outputs

Generate

docs/integration/interface-overview.md

docs/integration/rest-api.md

docs/integration/soap-services.md

docs/integration/message-queue.md

docs/integration/file-transfer.md

docs/integration/external-systems.md

---

## Quality Checklist

☐ REST documented

☐ SOAP documented

☐ MQ documented

☐ Kafka documented

☐ JMS documented

☐ File Transfer documented

☐ External Systems documented

☐ Authentication documented

☐ Message Formats documented

☐ Retry Strategy documented

☐ Evidence included

☐ No hallucinations

---

End.
