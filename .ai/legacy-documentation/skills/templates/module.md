# Module

> This template is MANDATORY for every file under `docs/modules/`.
>
> Per-unit depth requirements: see `shared/logic-depth.md`.

---

## Overview

Three to six sentences. State what business function this module performs, who or
what triggers it, and what it produces.

Name the primary unit type (transaction class, controller, batch job) and the unit count.

---

## Responsibilities

One bullet per responsibility. Each bullet names the packages or classes that carry it.

---

## Directory Structure

---

## Package Structure

---

## Entry Points

| Entry Point | Type | Trigger | Primary Unit Doc |
|-------------|------|---------|------------------|

---

## Public Interfaces

---

## Internal Components

---

## Transaction Class Index

One row per primary unit owned by this module.

Every row links to a depth-complete document under `transactions/`.
See `shared/logic-depth.md`.

| Class | Entry URL / Trigger | Purpose | Methods | Document |
|-------|---------------------|---------|---------|----------|

---

## Key Processing Flows

For each significant flow that crosses more than one class in this module, give a
numbered narrative naming the classes and methods in call order.

Link each step to the owning `transactions/<Class>.md#method-<name>` section.

---

## Dependencies

---

## Configuration

---

## Related Database Objects

---

## Related Business Rules

---

## Related Sequence

---

## Evidence
