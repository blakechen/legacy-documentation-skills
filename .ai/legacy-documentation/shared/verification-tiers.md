# Verification Tiers

## Objective

Make the strength of a run's verification explicit, so that documentation
produced without verification cannot be mistaken for documentation that
survived it.

---

## The Problem

This library's gates are commands. In an environment where nothing can be
executed, every gate silently degrades from a check into an assertion, and
the output looks exactly the same as a fully verified run.

That is worse than having no verification at all: a report that reads as
verified will be believed.

---

## The Tiers

| Tier | Condition | What the run may claim |
|---|---|---|
| **A** | Factbase built AND bytecode oracle reports `VERIFIED` | "Consistent with source; meaning not verified" |
| **B** | Factbase built, oracle reports `UNAVAILABLE` | "Consistent with source as read lexically; not independently verified" |
| **C** | Commands cannot be run in this environment | "VERIFICATION: NONE" |

An oracle status of `FAILED` is not a tier. It BLOCKS the pipeline.

---

## Declaring the tier

The tier is established once, before Phase 1, and persisted:

`docs/verification-tier.txt`

    tier|<A|B|C>
    reason|<one line>
    factbase|<PRESENT|ABSENT>
    oracle|<VERIFIED|UNAVAILABLE|NOT RUN>
    depth_checks|<RUN|NOT RUN>
    staleness|<RUN|NOT RUN>
    declared|<date>

In Tier A and B the file is written by `tools/verification_tier.sh`.
In Tier C the analyst writes it by hand, and the `reason` line names the
specific limitation (no shell, no file execution, read-only sandbox).

Every generated document SHALL carry the tier in its metadata block:

    Verification tier: B

A document with no tier line is treated as Tier C.

---

## Tier C: what still applies

Everything in this library that is method rather than measurement:

- `shared/enumeration-first.md` — enumerate before documenting; never sample
- `shared/iterative-depth.md` — document at the system's primary unit
- `shared/logic-depth.md` — the four depth elements per method
- `shared/business-rule-criteria.md` — the domain-variable test
- `shared/archetypes.md` — representative plus deltas
- `shared/prioritization.md` — reachability, churn and usage as an ordering
- `shared/reflexion-model.md` — the hypothesis map and its three outcomes
- `shared/evidence-rules.md` — the citation rule

These are the substance of the library. None of them needs a program.

---

## Tier C: what does NOT apply

The following SHALL NOT be claimed, stated, or implied:

- that the enumeration is complete
- a Depth-Complete Rate, in any form, including "approximately"
- that any excerpt has been checked against its source
- that a count has been verified
- that documentation is up to date with the current source
- the words **verified**, **confirmed**, **exhaustive**, **complete**, or
  **100%**, about any artefact this run produced

---

## Tier C: mandatory disclosures

Every index, report and summary produced in Tier C SHALL open with:

    VERIFICATION: NONE
    This run could not execute the verification tools. Counts, coverage and
    depth are unverified claims, not measurements.

The enumeration report SHALL additionally state:

    The enumeration was produced by reading. It has NOT been checked for:
    - transitive inheritance (a class reached only through an intermediate
      base class)
    - subclasses of a base class that ships outside the source tree
    - classes registered by reflection, named only in a string literal
    Any of these may be missing, and this run cannot say which.

The gap analysis SHALL NOT report a Depth-Complete Rate. It reports instead:

    Depth-Complete Rate: NOT MEASURED (Tier C)
    Units with a document: N of M
    Units whose document was checked against source: 0

---

## Tier C: confidence ceiling

No finding produced in Tier C may carry confidence **High**.

`shared/confidence-scoring.md` derives High from a fact in the factbase or a
fact confirmed by the oracle. In Tier C neither exists, so the evidence that
would justify High is absent by definition.

The ceiling is Medium. Unknown remains available and remains preferred.

---

## Upgrading

A Tier C run is not wasted work. When the same repository is later analysed
in an environment that can execute commands:

1. Build the factbase and run the oracle.
2. Compare the Tier C enumeration against the queried enumeration. The
   difference is a direct measurement of what reading missed, and SHALL be
   recorded.
3. Run the depth checks over the existing documents. Regenerate what fails.
4. Re-stamp every document with the new tier.

Step 2 is worth doing for its own sake. It is the only way this library
learns how large the gap between reading and parsing actually is on a real
system.

---

## Anti-Pattern

Producing Tier C documentation and omitting the disclosure is FORBIDDEN.

Estimating a Depth-Complete Rate in Tier C is FORBIDDEN. An estimate of a
measurement is not a measurement; it is the failure mode this library was
built to prevent, wearing the vocabulary of the fix.
