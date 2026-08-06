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
  - module-analysis
  - database-analysis

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
