# Enumeration-First Principle

## Objective

Before generating any documentation, build a complete inventory list of the target artifacts.

---

## Rule

Every Skill that produces per-item documents SHALL

1. First enumerate ALL items of the target type.

2. Record each item with its location and evidence.

3. Then iterate through EVERY item to generate its document.

4. Never stop after sampling a few items.

---

## Examples

### Transaction Classes

Enumerate every class that extends the transaction base class or is referenced by the dispatcher.

Generate one document per transaction class.

### Database Objects

Enumerate every class that extends the DB object base class.

Generate one table entry per DB object.

### Servlets

Enumerate every class that extends HttpServlet or is mapped in configuration.

---

## Anti-Pattern

Scanning a few representative files and generalizing is FORBIDDEN.

Stopping after the first 3-5 findings is FORBIDDEN.

Producing a single summary instead of per-item documents is FORBIDDEN.

---

## Enumeration Is a Query, Not a Search

The master lists are produced by `tools/factbase/enumerate.py` from the
factbase built by the `fact-extraction` Skill. See shared/fact-layer.md.

A Skill SHALL NOT build an enumeration by grepping for `extends <Base>`.

Three things that text search cannot do, and that the enumeration requires:

### Transitive inheritance

`A extends B`, `B extends StdTrxObject`. A search for `extends StdTrxObject`
returns B and misses A. The factbase stores the transitive closure of the
hierarchy, so A is found at depth 2. The enumeration report records the depth
of every entry; any entry with depth > 1 is one a text search would have
missed.

### External base classes

When the base class ships in a jar there is no source to read. The closure
still forms: the unresolved supertype becomes an `EXTERNAL:<SimpleName>`
node, and every class below it is still enumerated.

### Reflection registration

`Class.forName(prefix + code)` names no class in the source text. The
enumeration matches string literals against the type table and records which
entries were found this way, and which literals named no known class at all.
A literal that names nothing is a finding: a class outside the scanned roots,
or a dead registration.

---

## Verification

The count must be confirmed by an INDEPENDENT source, not by a second search.

    tools/factbase/verify_bytecode.py

reads compiled classes and jars with `javap` and compares the true supertype
of every class with the factbase. The two share no code and read different
inputs.

Running a similar search with a different regular expression is not
independent verification. It is the same method making the same mistake
twice.

If no compiled artefact exists, the oracle records `UNAVAILABLE` and the
enumeration report SHALL state that the result rests on lexical extraction
alone. The word "verified" SHALL NOT be used for that run.

---

## Mandatory Output Artifact

The enumeration MUST produce a persistent file (not just in-memory knowledge):

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`

Format:

- `transaction-classes.txt` — `ClassName|relative/path/to/File.java`
- `servlet-classes.txt` — `ClassName|relative/path/to/File.java`
- `db-object-classes.txt` — `ClassName|relative/path/to/File.java|TargetTable`

Write `UNKNOWN` as the target table when it cannot be determined. Never omit the field.

The `artifact-enumeration` Skill owns these files.

This file is the **gate** for all downstream Skills. No downstream Skill may begin until the enumeration file exists and contains a non-zero count.

---

## Lessons Learned

### Problem: Enumeration recognized but not persisted

In practice, the AI may identify counts (e.g., "~467 transaction classes") during analysis but fail to persist a machine-readable master list. Downstream Skills then have no authoritative source to iterate.

**Fix**: The enumeration step MUST write a file to disk. Validation = file exists AND line count > 0.

### Problem: Count approximation instead of exact list

Using `grep -c` or similar to get a count is NOT enumeration. Enumeration requires the actual list of class names and paths.

**Fix**: Always output `ClassName|Path` pairs, not just a count.

### Problem: Single-pass assumption

For large repositories (400+ artifacts), a single AI context window may not be able to enumerate and document all items in one pass.

**Fix**: Enumeration and documentation are separate steps. Enumeration completes first. Documentation may be batched across multiple passes, referencing the enumeration file.
