---
name: archetype-clustering

description: |
  Group primary units into archetypes by structural similarity so that a
  family of copy-and-paste units is documented once at full depth and each
  member is documented as a delta.

version: 1.0.0

category: analysis

author: Legacy Documentation Skills

tags:
  - clone-detection
  - archetype
  - scale
  - reverse-engineering

dependencies:
  - fact-extraction
  - artifact-enumeration

shared:
  - archetypes
  - fact-layer
  - evidence-rules
  - quality-checklist

outputs:
  - docs/enumeration/archetypes.txt
  - docs/enumeration/archetype-report.md
---

# Objective

Find the shapes behind the unit list.

Apply shared/archetypes.md.

---

# Responsibilities

This Skill SHALL

- cluster every enumerated primary unit by structural similarity

- choose a representative for each cluster

- record each member's similarity to its representative

- report how many full-depth documents the clustering avoids

This Skill SHALL NOT

- assume two units in a cluster behave identically

- write a member's document from the representative's source

- treat clustering as a reason to skip reading a member

---

# Inputs

docs/facts/factbase.sqlite

docs/enumeration/transaction-classes.txt

Source Code

---

# Deliverables

docs/enumeration/archetypes.txt

docs/enumeration/archetype-report.md

---

# Prompt

# Archetype Clustering Skill

## Step 1

Cluster.

    python3 tools/factbase/archetypes.py \
        --repo <repo> --db <repo>/docs/facts/factbase.sqlite \
        --enumeration <repo>/docs/enumeration

Default threshold 0.75. Lower it only with a stated reason, and record the
value used.

## Step 2

Read the report.

For every multi-member archetype, confirm by opening two members that the
clustering reflects real duplication and not an artefact of short files.

Record the confirmation. A cluster nobody looked at is a guess.

## Step 3

Assign documentation mode.

For each archetype

- representative: full-depth document, all four elements of
  shared/logic-depth.md
- other members: delta document per shared/archetypes.md
- single-member archetype: ordinary full-depth document

Write the assignment into `docs/enumeration/archetype-report.md`.

## Step 4

Hand the plan to the orchestrator.

The representative of each archetype SHALL be documented before any of its
members, because a delta has nothing to reference until the representative
exists.

---

# Completion Criteria

`docs/enumeration/archetypes.txt` exists with one entry per enumerated unit.

Every unit is assigned to exactly one archetype.

Every multi-member archetype has a named representative.

At least two members of each multi-member archetype have been opened and the
clustering confirmed.

---

# Required By

module-analysis

business-rule-extraction

specification-generation

gap-analysis

---

# Quality Checklist

☐ Threshold recorded

☐ Every unit assigned

☐ Representatives named

☐ Clustering confirmed by reading, per cluster

☐ Documentation mode assigned per unit

☐ No member documented from the representative's source alone

End.
