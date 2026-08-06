# Module Analysis

---

## Goal

Analyse every logical module in the repository.

Generate one document per module.

Describe module structure only.

Do not analyse business behaviour.

---

## Step 1

Identify Modules

Possible examples

loan

customer

payment

account

authentication

authorization

batch

report

scheduler

integration

notification

common

shared

security

api

Record

Module Name

Location

Evidence

---

## Step 2

Determine Module Responsibility

Describe

Primary Responsibility

Owned Features

Major Packages

Configuration Files

Avoid assumptions.

Only describe observable responsibilities.

---

## Step 3

Identify Entry Points

Examples

REST Controller

SOAP Endpoint

Message Listener

Batch Job

Scheduler

CLI

Servlet

Filter

Interceptor

Record

Type

Location

Evidence

---

## Step 4

Identify Public Interfaces

Examples

REST API

SOAP Interface

MQ Listener

Published Events

Public Services

Exported Packages

Record

Interface

Purpose

Evidence

---

## Step 5

Identify Internal Structure

Document

Packages

Sub-packages

Major Classes

Interfaces

Configuration

Resources

Utilities

Factories

Builders

Adapters

---

## Step 6

Identify Dependencies

Document

Internal Dependencies

External Dependencies

Shared Modules

Infrastructure Dependencies

Only document observable relationships.

---

## Step 7

Identify Configuration

Locate

application.yml

properties

XML

Annotations

Environment Variables

Module-specific Settings

Record

Purpose

Evidence

---

## Step 8

Generate Module Summary

Include

Purpose

Responsibilities

Entry Points

Interfaces

Dependencies

Important Classes

Configuration

External Systems

Evidence

---

## Output Format

Generate

docs/modules/module-index.md

Generate one document per module.

Example

loan.md

customer.md

payment.md

security.md

batch.md

---

## Module Document Structure

Every module document shall contain

# Overview

# Responsibility

# Directory Structure

# Package Structure

# Entry Points

# Public Interfaces

# Internal Components

# Important Classes

# Dependencies

# Configuration

# External Systems

# Evidence

---

## Output Rules

Never analyse business rules.

Never explain validation logic.

Never explain transaction flow.

Never infer undocumented behaviour.

Never generate sequence diagrams.

Never describe SQL logic.

---

## Quality Checklist

✓ Every module documented

✓ Responsibilities identified

✓ Entry points identified

✓ Public interfaces identified

✓ Package structure documented

✓ Dependencies documented

✓ Configuration documented

✓ Evidence included

✓ No hallucinations

✓ No business rules

---

End.