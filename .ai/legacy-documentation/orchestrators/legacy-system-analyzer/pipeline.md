# Pipeline

Stage 0

Fact Extraction

↓

Bytecode Oracle (independent verification)

Layers 1 and 2 of shared/fact-layer.md. Deterministic. No model.

---

Stage 1

Inventory

↓

Technology Discovery

↓

Architecture Discovery + Custom Framework Detection

---

Stage 1.5

Artifact Enumeration (queried from the factbase, not searched)

Transaction Class Enumeration (transitive closure + reflection)

↓

DB Object Class Enumeration

↓

Servlet Enumeration

↓

Prioritization (reachability + churn + runtime usage)

↓

Archetype Clustering (collapse copy-and-paste families)

---

Stage 1.6

Reflexion Check

A person's model of the system, tested against the factbase.

Divergence and absence resolved before Stage 2.

---

Stage 2

Module Analysis (per-module + per-unit, in priority order)

↓

Database Analysis (from DB object enumeration)

↓

Interface Analysis

---

Stage 3

Domain Variable Derivation

↓

Business Rule Extraction (per unit, domain-variable test applied)

↓

Sequence Discovery (per unit)

---

Stage 4

Per-Unit Specification Generation

↓

System Specification Generation

↓

Characterization Test Generation

↓

Gap Analysis (staleness, then depth, both by tool)
