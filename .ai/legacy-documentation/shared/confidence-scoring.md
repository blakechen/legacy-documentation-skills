# Confidence Scoring

## Objective

Express confidence consistently across all Skills.

---

## High

Direct evidence exists.

Examples

Method implementation

SQL

Annotation

Configuration

Repository Definition

---

## Medium

Evidence exists from multiple related artifacts.

Minor interpretation required.

Must cite all supporting evidence.

---

## Low

Evidence incomplete.

Possible interpretation only.

Document uncertainty clearly.

---

## Unknown

No evidence available.

Do not estimate.

---

## Derivation

Confidence is DERIVED from the kind of evidence, not chosen.

Self-assessed confidence from a language model is not calibrated, and a
four-level scale invites the middle two levels to absorb everything
uncertain.

| Evidence | Confidence |
|---|---|
| A fact in the factbase: declared type, method, supertype, literal, cited line range | High |
| A fact confirmed by the bytecode oracle | High |
| A relationship resolved across files by the factbase (resolved call, closure edge) | High |
| An inference from two or more cited facts, stated with both citations | Medium |
| A conclusion resting on naming similarity, convention, or a single ambiguous artefact | Low |
| No citable artefact | Unknown |

Where the factbase records `ambiguous`, `external` or `UNKNOWN` for the fact
in question, the finding that rests on it SHALL NOT be High.

Where no Layer 1 extractor exists for the language, no finding about that
language's code is High.

In Tier C no finding may be High at all. High is derived from a fact in the
factbase or a fact confirmed by the oracle, and in Tier C neither exists.
The ceiling is Medium. See shared/verification-tiers.md.

---

## Rules

Never increase confidence without evidence.

Never hide uncertainty.

Confidence applies to findings, not opinions.

State the derivation, not just the level: a bare "Confidence: Medium" is not
a confidence assessment.