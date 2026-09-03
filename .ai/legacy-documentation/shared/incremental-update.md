# Incremental Update

## Objective

Bind every document to the version of the source it describes, and re-run
only what has changed.

---

## The Problem

Evidence that cites `TransferTrx.java:120-128` is true of one version of that
file. The citation does not say which. A year later the document is either
still correct or describes code that no longer exists, and nothing in the
document distinguishes the two cases.

A pipeline with no version binding also has no incremental mode: every re-run
is a full re-run, which for a 458-unit system means it is never re-run.

---

## Rule

### Evidence carries a version

The factbase records, for every file, its sha256 and the commit the scan ran
against, in `docs/facts/hashes.psv` and `docs/facts/manifest.psv`.

Every generated document SHALL record, in its metadata block

    Factbase commit: <sha>
    Generated: <date>

### State is recorded after verification

After a batch reaches depth-complete, run

    tools/verify/staleness.sh ... --record

This writes, per unit, the sha256 of every source file the unit's document
cites -- the unit's own file plus every file named in an excerpt citation.

`docs/model/unit-state.psv`

### Re-runs check before regenerating

At the start of a later run

    tools/verify/staleness.sh ...

reports each unit as up to date, stale, or never recorded.

Stale units are regenerated. Everything else is left alone, and its recorded
state is carried forward.

---

## What counts as stale

A unit is stale when any file its document cites has a different sha256 from
the one recorded.

A unit is NOT stale merely because the commit moved. Most commits touch
nothing a given document cites.

---

## Rule for the orchestrator

A re-run over an already-documented repository SHALL begin with the staleness
report and SHALL state, before starting work

    N units total, M stale, K never documented

Regenerating an unchanged unit is waste. Leaving a stale unit in place is a
false claim about the current system. Both are failures.

---

## Interaction with depth checks

`depth_checks.sh` validates excerpts against the CURRENT source. A stale
document therefore usually fails the excerpt check as well.

The two tools answer different questions:

- staleness: has the source moved since this document was written?
- depth checks: does this document match the source as it is now?

Run staleness first. A stale document should be regenerated, not patched
until its excerpts pass.
