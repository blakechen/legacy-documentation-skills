---
name: reflexion-check

description: |
  Compare a person's stated model of the system against the relationships
  the factbase actually contains, and report convergence, divergence and
  absence. The only check in this library that uses knowledge the code
  does not contain.

version: 1.0.0

category: quality

author: Legacy Documentation Skills

tags:
  - reflexion
  - architecture
  - validation
  - top-down

dependencies:
  - fact-extraction
  - artifact-enumeration
  - architecture-discovery

shared:
  - reflexion-model
  - fact-layer
  - evidence-rules
  - quality-checklist

outputs:
  - docs/architecture/hypothesis-map.txt
  - docs/architecture/reflexion-report.md
---

# Objective

Test the recovered architecture against a belief formed independently of it.

Apply shared/reflexion-model.md.

---

# Responsibilities

This Skill SHALL

- obtain a hypothesis map written by a person who knows the system

- map every type in the factbase onto that model

- compute convergence, divergence and absence

- require a resolution for every divergence and every absence

- report every unmapped type

This Skill SHALL NOT

- generate the hypothesis map from the package structure and then test
  against it

- discard a divergence as a tool error

- treat a clean report as evidence when the map was derived from the code

---

# Inputs

docs/facts/factbase.sqlite

docs/architecture/hypothesis-map.txt

---

# Deliverables

docs/architecture/reflexion-report.md

---

# Prompt

# Reflexion Check Skill

## Step 1

Obtain the hypothesis.

Ask for a module map from someone who knows the system. Ten to fifteen
modules, the edges they expect between them, and a mapping rule per module.

If no such person is available, say so in the report and record the map's
author as the analyst. A map written by whoever read the code is weaker
evidence, and the report SHALL say which case applies.

Do NOT generate the map from package names as a substitute. A map derived
from the code cannot disagree with the code.

## Step 2

Run.

    python3 tools/reflexion/reflexion.py \
        --db <repo>/docs/facts/factbase.sqlite \
        --map <repo>/docs/architecture/hypothesis-map.txt \
        --out <repo>/docs/architecture/reflexion-report.md

## Step 3

Resolve every divergence.

For each, record one of

- an undocumented fact about the system, now written down
- a defect: a layering violation or a shortcut, recorded in the gap analysis
- a mapping-rule error, corrected in the map, with the correction noted

## Step 4

Resolve every absence.

For each, record one of

- the belief was wrong, and why
- the relationship exists by a mechanism this scan cannot see: name the
  mechanism (scheduler, queue, stored procedure, file transfer, operator
  script)
- the enumeration missed the classes that carry it. This outcome is a
  CRITICAL finding: return to artifact-enumeration.

## Step 5

Account for unmapped types.

An unmapped type means the model has no module for it, or it is not part of
the system the model describes. Decide which, per type or per group, and
record the decision.

---

# Completion Criteria

`docs/architecture/reflexion-report.md` exists.

Every divergence has a recorded resolution.

Every absence has a recorded resolution.

Unmapped types are accounted for.

The report states who wrote the hypothesis map.

---

# Required By

specification-generation

gap-analysis

---

# Quality Checklist

☐ Hypothesis map author recorded

☐ Map not derived from package structure

☐ Tool run and report generated

☐ Every divergence resolved

☐ Every absence resolved

☐ Unmapped types accounted for

☐ Enumeration re-opened where an absence pointed at missing classes

End.
