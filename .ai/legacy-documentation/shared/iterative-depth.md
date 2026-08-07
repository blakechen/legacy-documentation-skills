# Iterative Depth Principle

## Objective

Ensure documentation reaches the correct granularity level for each system.

---

## Rule

Every analysis Skill SHALL determine the system's primary unit of work and document at that level.

---

## Determining the Primary Unit

### Dispatcher-Based Systems

If the system uses a central dispatcher (e.g., TrxDispatcher, Front Controller, Action Servlet):

The primary unit is each **transaction/action class** registered with the dispatcher.

Each transaction class SHALL receive its own document.

### Controller-Based Systems (MVC/REST)

If the system uses REST controllers or MVC controllers:

The primary unit is each **controller class** or **endpoint group**.

### Batch-Based Systems

If the system is batch-oriented:

The primary unit is each **batch job** or **batch step**.

---

## Depth Requirements

For each primary unit, document:

- Entry point (state/method)

- All state methods or action methods

- Database objects accessed

- External systems called

- Business rules enforced

- Input parameters

- Output/redirect targets

- Error handling

---

## Anti-Pattern

Documenting only at the package or module level when the system has finer-grained transaction units is INSUFFICIENT.

Treating all transaction classes as one group is FORBIDDEN.

---

## Batching Strategy for Large Systems

When the primary unit count exceeds what can be processed in a single pass (typically > 20 units):

1. Group units by module/package (e.g., `com.abank.trx`, `com.lb.wibc.trx`).

2. Process one group at a time, completing all depth requirements for that group before moving to the next.

3. Track progress explicitly (e.g., "batch 1 of N complete, M/Total classes documented").

4. Never produce a summary document as a substitute for per-unit documents.

---

## Lessons Learned

### Problem: Module-level summary treated as complete

The AI produced `docs/modules/module-index.md` (one summary file) instead of 458 per-transaction documents. This violates iterative-depth because the system's primary unit is the transaction class, not the module.

**Fix**: After Architecture Discovery identifies a dispatcher pattern, the Skill MUST confirm: "Primary unit = transaction class. Expected document count = [enumeration count]. I will produce one file per class."

### Problem: Depth skipped due to scale

When facing 400+ classes, the AI defaulted to high-level summaries rather than attempting even a subset at proper depth.

**Fix**: It is acceptable to process in batches. It is NOT acceptable to skip depth entirely. Even if only 6 classes are documented per pass, those 6 must be at full depth. Progress tracking ensures eventual completion.
