# Custom Framework Recognition

## Objective

Legacy systems often use custom or proprietary frameworks instead of well-known ones (Spring, Jakarta EE).
Skills SHALL recognize and document these patterns.

---

## Detection Rules

### Custom Dispatcher Pattern

If a single Servlet receives all requests and routes to transaction classes based on a parameter (e.g., `trx`, `action`, `command`):

- Identify the dispatcher class.

- Identify the routing parameter(s).

- Identify the base transaction class.

- Enumerate ALL registered or referenced transaction classes.

### Custom ORM Pattern

If database access uses a base class with programmatic field definitions (e.g., `addField()`, `setTargetTable()`) instead of annotations:

- Identify the base DB object class.

- Enumerate ALL subclasses.

- Extract table name from `setTargetTable()`.

- Extract field definitions from `addField()` calls.

- Reconstruct the schema from code.

### Custom Configuration Pattern

If configuration is loaded from a custom path (e.g., `ConfigManager.load("/usr/hncb/config/init")`):

- Identify the configuration loader.

- Enumerate ALL properties files.

- Map properties files to the modules that consume them.

---

## Evidence

When documenting custom frameworks, always record:

- Base class name

- Discovery pattern (how subclasses are found)

- Registration mechanism

- Configuration source

---

## Anti-Pattern

Reporting "no framework detected" when a custom framework exists is INCORRECT.

Skipping analysis because the framework is not a well-known one is FORBIDDEN.

---

## Lessons Learned

### Problem: Custom framework detected but not used to drive enumeration

The AI correctly identified `TrxDispatcher` + `TrxFactory` + `StdTrxObject` as a custom framework, but then failed to use this information to drive a complete enumeration. Instead it produced approximate counts and moved on.

**Fix**: When a custom framework is detected, the NEXT mandatory step is:
1. Write the detection result to `docs/enumeration/framework-detection.md`
2. Use the base class name (e.g., `StdTrxObject`) as a grep pattern to produce the full enumeration file
3. Do NOT proceed to Phase 2 until the enumeration file is written

### Problem: Base class in external jar

When the base class (`StdTrxObject`) is not in the source tree (it's in an external jar), the AI cannot read its source. This does NOT excuse skipping enumeration of subclasses.

**Fix**: Search for `extends [BaseClassName]` across the entire source tree. The base class source is not needed for enumeration; only the `extends` keyword in subclasses is needed.
