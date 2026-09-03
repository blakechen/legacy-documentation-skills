# Archetypes

## Objective

Document a family of copy-and-paste units once, and record what each member
changes.

---

## The Observation

Legacy transaction classes are not written; they are copied. A system with
458 transaction classes typically holds a few dozen shapes, each duplicated
with a different table, field set and error code.

Producing 458 independent full-depth documents is expensive, and for a reader
it is worse than the alternative: the thing worth knowing is the shape and
the delta, and 458 near-identical documents hide both.

---

## Method

`tools/factbase/archetypes.py` normalises each unit into a token stream --
identifiers, literals and type names collapsed, invoked method names kept --
takes 5-gram shingles, and clusters by Jaccard similarity.

This finds type-1 and type-2 clones: identical code, and code that differs
only by names and literals. That is what copy-and-paste produces.

It does not find type-4 semantic clones. Two units that solve the same
problem with different code will not cluster, and SHALL NOT be assumed
equivalent because they did not.

---

## Documentation Rule

For a multi-member archetype:

### The representative

Gets an ordinary full-depth document under
`docs/modules/transactions/<Representative>.md`, satisfying every element of
`shared/logic-depth.md`.

### Every other member

Gets a **delta document** at `docs/modules/transactions/<Member>.md`
containing

1. `Archetype: ARCH-NNN` and a link to the representative's document
2. the measured similarity
3. a Differences table

   | Aspect | Representative | This unit | Evidence |
   |---|---|---|---|

   with one row for every difference in: target table, domain fields, error
   codes, validation constants, called services, output target
4. its own Field Mapping table, in full -- the fields are the difference,
   so they are never inherited by reference
5. an explicit statement of what is identical, naming the representative's
   sections that apply unchanged

A delta document is depth-complete when the Differences table is complete.

---

## Verification

Completeness of a delta is checked against the factbase, not by reading:

- every domain variable the member touches appears in its Field Mapping or in
  the Differences table
- the member's public method set matches the representative's, or the
  difference is a row in the table

A member whose similarity to its representative is below the clustering
threshold SHALL NOT be documented as a delta. It gets a full document.

---

## Single-member archetypes

Get an ordinary full-depth document. Nothing changes for them.

---

## Anti-Pattern

Using an archetype to avoid reading a member is FORBIDDEN. The delta is
produced by comparing the member's source against the representative's
source, not by assuming similarity implies sameness.

Clustering tells you where to look. It does not tell you what you will find.
