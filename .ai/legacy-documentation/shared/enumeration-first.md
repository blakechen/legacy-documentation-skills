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

## Verification

The enumeration list count must match the actual file count for that artifact type.

If they do not match, re-scan.

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
