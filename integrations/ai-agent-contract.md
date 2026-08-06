# AI Agent Contract

## Objective

Define the execution contract for every supported AI coding assistant.

---

## General Rules

Every AI shall

- execute the orchestrator

- respect Skill dependencies

- generate deterministic outputs

- avoid hallucination

- preserve evidence

---

## Workflow

Repository

↓

Orchestrator

↓

Skills

↓

Templates

↓

Gap Analysis

---

## Required Behaviour

Never execute Skills out of order.

Never bypass validation.

Never rewrite previous outputs.

Never invent undocumented behaviour.

---

## Failure Behaviour

If evidence is insufficient

Output

Unknown

Continue only when downstream dependencies permit.

Otherwise stop.

---

## Success Criteria

All required documents generated.

Gap Analysis completed.

No missing references.