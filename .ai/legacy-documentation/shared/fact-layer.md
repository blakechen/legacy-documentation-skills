# Fact Layer Principle

## Objective

Separate what can be established mechanically from what requires judgement,
and let the AI do only the second.

---

## The Three Layers

### Layer 1 - Facts

Deterministic extraction from source, build output and version control.

Produced by a program. No model involved.

Contents

- declared types, their supertypes, their files and line ranges
- declared methods, their modifiers, their spans, their decision counts
- call sites, string literals, imports, package structure
- file content hashes and the commit the scan ran against

Tool: `tools/factbase/extract_java.py` then `tools/factbase/build_factbase.py`.

Output: `docs/facts/*.jsonl` and `docs/facts/factbase.sqlite`.

### Layer 2 - Structure

Derived from Layer 1 by a program. Still no model.

Contents

- the transitive closure of the type hierarchy
- the call graph and reachability from entry points
- clone clusters
- change frequency
- the reflexion mapping against a stated hypothesis

Tools: `enumerate.py`, `prioritize.py`, `archetypes.py`,
`domain_variables.py`, `reflexion.py`.

### Layer 3 - Concepts

The only layer the AI owns.

Contents

- what a unit is for, in business terms
- the meaning of a cryptic name
- the business rule behind a condition
- the narrative of a processing flow

Every Layer 3 statement SHALL cite a Layer 1 fact: a path with a line range,
a table name from the enumeration, a domain variable from the derived list.

---

## Rule

A Skill SHALL NOT establish by reading what a tool can establish by parsing.

Specifically, a Skill SHALL NOT

- count artefacts by reading files
- decide a class hierarchy by grepping for `extends`
- assert that a method has N branches without the factbase
- assert a table name without the enumeration entry that carries it

---

## Why

A language model reading source code produces plausible facts. Plausible is
not the same as correct, and the failure is silent: nothing in the output
distinguishes a class it read from a class it expected to exist.

A parser produces a smaller set of facts and is wrong in ways that are
visible and reproducible. Where the two disagree, the parser wins.

---

## What the fact layer does NOT do

It does not understand the system.

`extract_java.py` is a lexical scanner, not a compiler. It records what is
written, resolves names through imports and package scope, and marks what it
cannot resolve as `EXTERNAL:` or `UNKNOWN`. Its known limits are listed in
the module docstring and SHALL be repeated in the enumeration report.

This is why Layer 1 has an oracle.

---

## The Oracle

`tools/factbase/verify_bytecode.py` reads compiled classes and jars with
`javap` and compares the true supertype of every class against the factbase.

The lexical scanner and the oracle share no code and read different inputs.
Agreement between them is evidence.

Re-running a similar search with a different regular expression is not
evidence. It is the same method making the same mistake twice.

When no compiled artefact exists, the oracle records
`Status: UNAVAILABLE` and the enumeration report SHALL say that the
enumeration rests on lexical extraction alone. It SHALL NOT be described as
verified.

---

## Order

The fact layer runs BEFORE architecture discovery consumes it and BEFORE
any enumeration file is written.

No Skill that produces documentation may run before
`docs/facts/factbase.sqlite` exists.

---

## Languages

Layer 1 is language-specific; Layers 2 and 3 are not.

`extract_java.py` covers Java, and by construction most of Kotlin's and
Scala's declaration syntax is out of its scope. A new language needs a new
Layer 1 extractor emitting the same JSONL records. Nothing above Layer 1
changes.

Where no extractor exists for a language, that fact SHALL be recorded and
the affected findings SHALL carry confidence Low, not High.
