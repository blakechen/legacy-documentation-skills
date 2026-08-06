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

✓ REST documented

✓ SOAP documented

✓ MQ documented

✓ Kafka documented

✓ JMS documented

✓ File Transfer documented

✓ External Systems documented

✓ Authentication documented

✓ Message Formats documented

✓ Retry Strategy documented

✓ Evidence included

✓ No hallucinations

---

End.