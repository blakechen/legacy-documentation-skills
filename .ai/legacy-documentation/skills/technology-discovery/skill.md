---
name: technology-discovery

description: |
  Discover technologies, frameworks, runtime environments,
  libraries and infrastructure components used by the repository.

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - technology
  - framework
  - runtime
  - discovery

supported-languages:
  - Java
  - Kotlin
  - Scala
  - COBOL
  - C#
  - VB.NET
  - Node.js
  - JavaScript
  - TypeScript
  - Python
  - Go
  - PHP

dependencies:
  - inventory

outputs:
  - docs/overview/technology-stack.md
  - docs/overview/frameworks.md
  - docs/overview/runtime-environment.md
  - docs/overview/dependency-summary.md
---

# Objective

Discover technologies used by the repository.

Only identify observable technologies.

Do not analyse architecture.

Do not analyse business logic.

---

# Responsibilities

This Skill SHALL

- identify programming languages

- identify frameworks

- identify runtime

- identify application servers

- identify databases

- identify ORM frameworks

- identify logging frameworks

- identify testing frameworks

- identify build systems

- identify dependency managers

- identify messaging technologies

- identify cache technologies

- identify scheduling technologies

- identify container technologies

- identify cloud technologies

- identify API technologies

- identify security frameworks

This Skill SHALL NOT

- infer architecture

- analyse business rules

- analyse source code flow

- generate specifications

- generate sequence diagrams

---

# Inputs

Repository Inventory

Build Files

Configuration Files

Dependency Definitions

Container Files

---

# Deliverables

docs/overview/

technology-stack.md

frameworks.md

runtime-environment.md

dependency-summary.md

---

# Evidence Rule

Every identified technology must be supported by evidence.

Examples

pom.xml

build.gradle

package.json

Dockerfile

server.xml

application.yml

Imports

Annotations

Configuration

Unknown is acceptable.

Never guess.

---

# Completion Criteria

Every major technology has been classified.

Every framework has evidence.

Every runtime has evidence.

Every database technology has evidence.

---

# Required By

architecture-discovery

module-analysis

database-analysis

interface-analysis

---

# Prompt

# Technology Discovery

---

## Goal

Identify every technology used by the repository.

This Skill documents technologies only.

Do not analyse software design.

---

## Step 1

Identify Programming Languages

Examples

Java

Kotlin

Scala

COBOL

JavaScript

TypeScript

C#

Python

Go

PHP

SQL

XML

YAML

JSON

Shell

Record

Language

Version if known

Evidence

---

## Step 2

Identify Frameworks

Examples

Spring Boot

Spring MVC

Spring Security

Jakarta EE

Java EE

EJB

Hibernate

MyBatis

Express

NestJS

ASP.NET

Django

Flask

React

Angular

Vue

Record

Framework

Version

Evidence

---

## Step 3

Identify Runtime

Examples

JDK

.NET Runtime

Node.js

Python

Go Runtime

PHP Runtime

Record

Runtime

Version

Evidence

---

## Step 4

Identify Application Servers

Examples

WebSphere

Tomcat

JBoss

WildFly

WebLogic

Jetty

Undertow

Record

Server

Version

Evidence

---

## Step 5

Identify Build Systems

Examples

Maven

Gradle

Ant

npm

pnpm

yarn

MSBuild

Make

Record

Tool

Version

Wrapper

Evidence

---

## Step 6

Identify Databases

Examples

Oracle

DB2

SQL Server

PostgreSQL

MySQL

MariaDB

SQLite

MongoDB

Redis

Record

Database

Driver

Evidence

---

## Step 7

Identify ORM

Examples

Hibernate

JPA

MyBatis

JDBC

Entity Framework

Dapper

Record

ORM

Evidence

---

## Step 8

Identify Messaging

Examples

IBM MQ

JMS

Kafka

RabbitMQ

ActiveMQ

Azure Service Bus

AWS SQS

Record

Technology

Evidence

---

## Step 9

Identify API Technologies

Examples

REST

SOAP

GraphQL

gRPC

JAX-RS

OpenAPI

Swagger

Record

Technology

Evidence

---

## Step 10

Identify Security

Examples

Spring Security

JAAS

LDAP

OAuth

OIDC

JWT

SAML

TLS

SSL

Record

Technology

Evidence

---

## Step 11

Identify Logging

Examples

SLF4J

Logback

Log4j

java.util.logging

NLog

Serilog

Record

Technology

Evidence

---

## Step 12

Identify Testing

Examples

JUnit

Mockito

Spock

TestNG

Jest

Mocha

PyTest

NUnit

Record

Technology

Evidence

---

## Step 13

Identify Containers

Examples

Docker

Docker Compose

Kubernetes

OpenShift

Helm

Podman

Record

Technology

Evidence

---

## Step 14

Identify CI/CD

Examples

GitHub Actions

GitLab CI

Jenkins

Azure DevOps

Bamboo

Record

Technology

Evidence

---

## Output Rules

Classify only.

Never infer architecture.

Never infer dependencies between modules.

Never explain execution flow.

Never describe business rules.

---

## Required Outputs

Generate

docs/overview/technology-stack.md

docs/overview/frameworks.md

docs/overview/runtime-environment.md

docs/overview/dependency-summary.md

---

## Quality Checklist

??Every language classified

??Every framework classified

??Runtime identified

??Build tools identified

??Databases identified

??ORM identified

??Messaging identified

??Security identified

??Logging identified

??Testing identified

??Container technologies identified

??CI/CD identified

??Evidence included

??No hallucinations

---

End.
