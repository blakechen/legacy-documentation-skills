# Logic Depth Principle

## Objective

Ensure each primary unit's document explains HOW the program works, not only WHAT artifacts it touches.

---

## Rule

For EVERY primary unit (transaction class, controller, batch job) and for EVERY public method of that unit, the document SHALL contain all four depth elements:

1. Processing Flow - numbered step-by-step narrative

2. Pseudocode - language-neutral restatement of the method

3. Key Source Excerpts - quoted code with file path and line numbers

4. Field Mapping - input field to variable to database column or message field

A fact table (method name plus a one-line description) does NOT satisfy this rule.

---

## 1. Processing Flow

Numbered steps. Minimum 3 steps per method.

If a method genuinely has no branching, write the literal sentence:

`Method body contains no branching logic; it only <observed action>.`

Each step SHALL state at least one of:

- what it reads (request parameter, session attribute, database row, configuration key)

- what it checks (the condition, and what happens when true and when false)

- what it calls (class.method, SQL statement, external system)

- what it writes (database column, session attribute, output field, log)

- where it goes next (next state, JSP, redirect, exception)

Always write the branch outcome. Never write a bare verb.

Bad

```
1. Validates the input.
```

Good

```
1. Reads request parameter TRSFAMT and parses it to BigDecimal.
2. If TRSFAMT > the daily limit read from LIMIT_CTL.DAILY_MAX, sets error code E0031
   and returns state prompt; otherwise continues to step 3.
3. Calls TransferService.execute with the parsed amount and the account read from session.
```

---

## 2. Pseudocode

One fenced block per method.

Language-neutral. No Java, COBOL or framework API names.

Use READ / WRITE / IF / ELSE / FOR EACH / CALL / RETURN.

Pseudocode SHALL cover every branch present in the source.

Pseudocode SHALL NOT introduce logic that is not in the source.

---

## 3. Key Source Excerpts

Quote the source for every critical decision, calculation and SQL statement.

Format

`path/to/File.java:120-128`

```java
<verbatim source lines>
```

Minimum one excerpt per method that contains a branch, a calculation or a SQL statement.

A method with none of these records the literal sentence:

`No critical logic; no excerpt required.`

Excerpts SHALL be verbatim. Never paraphrase inside a code fence.

Excerpts SHALL be short, typically under 30 lines. Quote the decision, not the file.

---

## 4. Field Mapping

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|

Target Kind is one of

DB column

external message field

session attribute

output page field

log

If the method moves no data, write the single row

`| None | - | - | - | - | - |`

---

## Applies To

`docs/modules/transactions/<Class>.md`

Owner: module-analysis. All four elements.

`docs/specifications/transactions/<Class>.md`

specification-generation. Processing Flow, Pseudocode and Field Mapping are carried forward. Source excerpts are replaced by a reference to the module document.

---

## Anti-Pattern

Summarising a method in one table row is FORBIDDEN.

Writing "handles the transfer logic" without naming fields, conditions and targets is FORBIDDEN.

Omitting depth because the unit count is large is FORBIDDEN. Use batching instead.

Reducing depth to keep the document short is FORBIDDEN. Length is not a defect.

---

## Definition of Depth-Complete

A unit document is DEPTH-COMPLETE when ALL of the following are true.

1. Every public method listed in the State Methods index has a matching `### Method: <name>` subsection.

2. The `### Method:` subsection count equals the number of public methods declared in the source class.

3. Every method subsection has a Processing Flow with at least 3 numbered steps, or the explicit trivial-method sentence.

4. Every method subsection has a non-empty Pseudocode fenced block.

5. Every method subsection has at least one source excerpt with `path:line-line`, or the explicit no-critical-logic sentence.

6. Every method subsection has a Field Mapping table with at least one row. The None row is allowed.

A unit that is not DEPTH-COMPLETE is NOT counted as documented, regardless of whether its file exists.

---

## Verification

Depth-Complete is decided by a program, not by reading.

    sh tools/verify/depth_checks.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/gap-analysis/depth-report.md

Four checks, described in shared/mechanical-verification.md:

| Check | Decides |
|---|---|
| structure | the six conditions above, using the factbase for the method list |
| excerpts | every quoted block is byte-identical to the lines it cites |
| branches | pseudocode branch count is consistent with source decision count |
| fields | every mapped field exists in the method; every table is enumerated |

Depth-Complete Rate = depth-complete units / enumeration line count.

The pipeline is complete only when the rate is 100% AND the tool exits 0.

A rate asserted without running the tool is not a rate.

### What passing does not mean

These checks decide consistency with the cited source. They do not decide
whether the business meaning is right. A document can pass every check and
still describe a correctly quoted method with the wrong purpose.

Report a passing run as "consistent with source; meaning not verified".

### Delta documents

A member of a multi-member archetype is documented as a delta against its
representative. See shared/archetypes.md. Its completion criterion is the
completeness of its Differences table and its own Field Mapping, not the
presence of all four elements restated.

---

## Lessons Learned

### Problem: Coverage gated, depth not gated

Enumeration and iterative-depth made the pipeline produce one file per class, but each file was a set of fact tables. Readers could not understand what the program does. File existence was the only completion check.

**Fix**: Completion is measured by the Definition of Depth-Complete above, not by file count. Gap Analysis reports depth failures per unit.

### Problem: Depth traded away for breadth

When facing 400+ units, the agent shortened every document instead of documenting fewer units fully.

**Fix**: Batch. Six depth-complete documents beat 458 shallow ones. Record remaining units in `docs/gap-analysis/progress.md`.
