# Prioritization

## Objective

Decide the order in which units are documented.

Coverage is unchanged: every enumerated unit gets a document. This decides
only what gets documented first, and therefore what gets documented at all
when the work is stopped early.

---

## The Problem

Batching by package name is alphabetical order wearing a plan's clothes.

It spends the same effort on a unit nothing has called since 2011 as on the
one that moves money, and it hides that fact behind a progress percentage.

---

## Signals

`tools/factbase/prioritize.sh` combines three signals that already exist in
the repository.

### Reachability (weight 0.45)

Can an entry point actually reach this unit?

Computed over the call graph, including

- resolved calls and constructor calls
- reflection edges, where a string literal names a known type
- inheritance, because a reachable subclass makes its in-tree ancestors
  reachable

An unreachable unit is a candidate for dead code. It is a candidate, not a
verdict: schedulers, message listeners, JCL and operator scripts are entry
points this scan does not model. Confirm before treating anything as dead.

### Change frequency (weight 0.25)

`git log --name-only` over the unit's file.

Code that changes is code that is understood badly and needed often. Both
make documentation worth more.

### Runtime usage (weight 0.30)

Optional, supplied by the site: a CSV of unit name and call count, drawn from
production logs, and a mapping file from routing code to class name where
the two differ.

This is the strongest signal and the only one the repository cannot supply.
When it is absent the weight contributes zero and the report says so.

---

## Rule

The orchestrator SHALL consume `docs/enumeration/priority.txt` and
`docs/enumeration/batches.txt` rather than dividing work by package.

Batch size stays small: 5 to 10 units per pass when full depth is required.
A batch is complete only when every unit in it is depth-complete. Reducing
depth to fit a batch is FORBIDDEN. Reduce the batch size instead.

---

## Reporting

`docs/enumeration/priority-report.md` SHALL be read before the first batch
and SHALL record

- the weights used
- whether runtime usage was supplied
- every unreachable unit, listed by name
- the reflection edges that were used to establish reachability

---

## What this does not license

It does not license skipping the tail.

An unreachable unit still gets a document. It gets one last, and its document
may state that no entry point reaching it was found, with the evidence for
that claim.
