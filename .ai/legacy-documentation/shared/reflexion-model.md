# Reflexion Model

## Objective

Test the recovered architecture against a person's belief about the system,
and report where the two disagree.

Murphy, Notkin and Sullivan, *Software Reflexion Models*, FSE 1995.

---

## The Problem

Every Skill in this library works bottom-up: it reads code and builds a
picture. Bottom-up recovery has no way to notice what it never found, and no
way to notice that what it found is not what the system is for.

Someone at the site knows what the system does. That knowledge is the only
input to this pipeline that is independent of the code, and until now the
pipeline had no place to put it.

---

## Method

### 1. State the hypothesis

A person who knows the system -- operations, a business analyst, a long-serving
developer -- writes a module map BEFORE reading the recovered documentation.

Ten to fifteen modules. Thirty minutes.

`docs/architecture/hypothesis-map.txt`

    module Web          Front controller, routing, request entry
    module Inquiry      Read-only enquiries
    module Transfer     Money movement
    module Persistence  Database access

    map ^com\.example\.bank\.web\.   -> Web
    map InquiryTrx$                   -> Inquiry
    map ^com\.example\.bank\.db\.     -> Persistence

    edge Web -> Inquiry
    edge Web -> Transfer
    edge Inquiry -> Persistence

Mapping rules are regular expressions over the fully qualified type name,
evaluated in file order; first match wins.

### 2. Compute

`tools/reflexion/reflexion.py` maps every type onto a module and compares
the expected edges with the edges the factbase actually contains.

### 3. Read the three results

**Convergence** - expected and present. Confirms the belief. The least
interesting outcome.

**Divergence** - present, not expected. A relationship nobody had written
down. Either an undocumented fact about the system, or a defect: a layering
violation, a shortcut, a leftover.

**Absence** - expected, not present. Either the belief was wrong, or the
relationship travels by a route the scan cannot see: a scheduler, a queue, a
stored procedure, a file drop.

**Unmapped types** - matched no rule. Not a neutral result. Either the model
is missing a module, or the type is not part of the system the model
describes. Both are worth knowing.

---

## Rule

The reflexion check SHALL run after enumeration and before specification
generation.

Every divergence and every absence SHALL be resolved in
`docs/architecture/reflexion-report.md` with one of

- a correction to the hypothesis map, and why
- a finding recorded in the gap analysis, and why
- a stated limit of the scan, naming the mechanism it cannot see

An unresolved divergence is an open question about the system, not a tool
error to be ignored.

---

## Why this catches extraction errors

The hypothesis is written from knowledge the extractor does not have. When a
module the analyst is certain exists maps to nothing, the likely cause is not
that the analyst is wrong. It is that the enumeration missed a family of
classes.

This is the only check in the library that can find something the pipeline
never looked for.

---

## Anti-Pattern

Generating the hypothesis map from the package structure is FORBIDDEN as a
substitute for a person writing one.

A map derived from the code cannot disagree with the code. Running the tool
against such a map produces a clean report that means nothing, and the clean
report is worse than no report because it will be believed.
