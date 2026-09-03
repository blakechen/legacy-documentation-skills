# Mechanical Verification

## Objective

Make the completion criteria of this library decidable by a program.

---

## Rule

A completion claim that no program can refute is not a completion claim.

Every gate in this library SHALL be expressed as a command with an exit
status, and the orchestrator SHALL run it rather than assert its outcome.

---

## The Gates

| Gate | Command | Pass |
|---|---|---|
| Factbase exists | `build_factbase.sh` | `docs/facts/ancestor.psv` written |
| Enumeration is derived, not guessed | `enumerate.sh` | three master lists written from the factbase |
| Enumeration is independently checked | `verify_bytecode.sh` | exit 0 and `Status: VERIFIED`, or a recorded `UNAVAILABLE` |
| Documents are depth-complete | `depth_checks.sh` | exit 0, rate 100% |
| Documents describe the current source | `staleness.sh` | exit 0 |
| The architecture model survives contact | `reflexion.sh` | divergences and absences each explained |

---

## The Four Depth Checks

Run by `tools/verify/depth_checks.sh`.

### structure

Every public method declared in the source class has a `### Method:`
subsection, and every subsection names a real public method. Each subsection
has a Processing Flow with at least three numbered steps, a non-empty
Pseudocode block, an excerpt citation or the explicit no-critical-logic
sentence, and a Field Mapping table with at least one row.

The method list comes from the factbase, not from the document.

### excerpts

Every quoted code block is byte-identical to the lines it cites.

A block that matches only after re-indentation is a warning. A block whose
content differs, whose range is out of bounds, or whose file does not exist
is a failure.

This is the single strongest hallucination detector in the library: quoted
code that does not exist in the file it cites is an invention, and no
plausible prose can disguise it.

### branches

The number of control constructs in the Pseudocode is compared with the
number of decision points in the method's source.

- More constructs than the source has decision points: FAIL. Logic that is
  not in the source has been introduced.
- Fewer than 60% of the source's structural decisions: FAIL. Branches have
  been dropped.

The upper bound counts `&&` and `||`, because one pseudocode `IF` may
legitimately cover a compound condition. The lower bound does not.

### fields

Every name in a Field Mapping row appears in the method's source text, and
every `DB column` target names a table present in
`docs/enumeration/db-object-classes.txt`.

---

## What these checks decide

Consistency between a document and the code it cites.

## What they do not decide

Whether the business meaning is right.

A document can pass every check and still assign the wrong purpose to a
correctly described method. Mechanical verification removes the failures that
are cheap to detect so that human review can spend itself on the ones that
are not.

Do not report a passing run as "verified documentation". Report it as
"consistent with source; meaning not verified".
