# Inventory Skill

---

## Goal

Scan the entire repository recursively.

Create a complete inventory.

Do not perform architectural analysis.

Do not infer business logic.

Only document observable facts.

---

## Step 1

Identify Repository Type

Determine whether the repository is

- Monorepo

- Multi-module

- Single Application

- Multi Repository Import

Record evidence.

---

## Step 2

Identify Projects

Locate every project.

Examples

Java

Node

.NET

Python

Go

PHP

COBOL

Record

Project Name

Location

Primary Language

Framework if known

Build Tool

Entry Point

---

## Step 3

Identify Modules

For every project

identify logical modules.

Examples

loan

payment

customer

batch

shared

common

security

api

web

scheduler

---

## Step 4

Programming Languages

Identify every language.

Examples

Java

Kotlin

Groovy

Scala

COBOL

JavaScript

TypeScript

C#

Python

SQL

XML

YAML

JSON

Properties

Shell

PowerShell

Batch

---

## Step 5

Build System

Identify

Gradle

Maven

Ant

npm

pnpm

yarn

MSBuild

Make

CMake

Record

version if available

wrapper

plugins

---

## Step 6

Dependency Managers

Locate

pom.xml

build.gradle

build.gradle.kts

package.json

packages.config

requirements.txt

go.mod

composer.json

Record

dependency manager

dependency count

important libraries

---

## Step 7

Configuration Files

Locate

application.yml

application.properties

bootstrap.yml

server.xml

web.xml

context.xml

ibm-web-ext.xml

ibm-web-bnd.xml

docker-compose.yml

Dockerfile

.env

Record

purpose

location

---

## Step 8

Infrastructure

Locate

Docker

Kubernetes

Helm

Terraform

Ansible

OpenShift

GitHub Actions

GitLab CI

Jenkins

Azure DevOps

---

## Step 9

Database Indicators

Locate

SQL

DDL

Liquibase

Flyway

Hibernate

MyBatis

Stored Procedures

---

## Step 10

Integration Indicators

Locate

REST

SOAP

MQ

Kafka

FTP

SFTP

JMS

gRPC

RabbitMQ

---

## Step 11

Documentation

Locate

README

Architecture

Wiki

Design

ADR

Decision Records

Specifications

Runbooks

---

## Step 12

Statistics

Collect

Total Files

Directories

Projects

Modules

Languages

Configuration Files

Documentation Files

SQL Files

Tests

Build Files

---

# Output Rules

Never describe architecture.

Never describe business rules.

Never infer relationships.

Never explain workflows.

Inventory only.

---

# Required Outputs

Generate

docs/overview/system-overview.md

docs/overview/project-structure.md

docs/overview/repository-inventory.md

docs/overview/file-statistics.md

---

# Quality Checklist

✓ Every directory indexed

✓ Every project indexed

✓ Every module indexed

✓ Every build file indexed

✓ Every configuration indexed

✓ Every language identified

✓ No assumptions

✓ No hallucinations

✓ Evidence available

---

End.